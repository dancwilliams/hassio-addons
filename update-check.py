"""Open a PR when ChirpStack or the Gateway Bridge publishes a new release.

Runs daily from .github/workflows/update-check.yaml. Bumps the Dockerfile ARGs,
the version strings in config.json/README.md/DOCS.md, and prepends a CHANGELOG
entry. The CI build + smoke test on the resulting PR is the merge gate.

Usage: update-check.py [true]   ("true" = pull_request dry run: no push, no PR)
"""
import difflib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

ADDON = "chirpstack-addon"
UPSTREAM = {  # Dockerfile ARG -> (GitHub repo, label, download URL template)
    "CHIRPSTACK_VERSION": (
        "chirpstack/chirpstack", "ChirpStack",
        "https://artifacts.chirpstack.io/downloads/chirpstack/chirpstack_{v}_sqlite_linux_{arch}.tar.gz",
    ),
    "GATEWAY_BRIDGE_VERSION": (
        "chirpstack/chirpstack-gateway-bridge", "Gateway Bridge",
        "https://artifacts.chirpstack.io/downloads/chirpstack-gateway-bridge/chirpstack-gateway-bridge_{v}_linux_{arch}.tar.gz",
    ),
}
dry_run = len(sys.argv) > 1 and sys.argv[1] == "true"
token = os.environ.get("GITHUB_TOKEN")
repo = os.environ.get("GITHUB_REPOSITORY")
headers = {"Accept": "application/vnd.github+json"}
if token:
    headers["Authorization"] = f"token {token}"


def http(url, method="GET", data=None):
    req = urllib.request.Request(url, method=method, headers=headers, data=data)
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.status, r.read()


def latest(gh_repo):
    _, body = http(f"https://api.github.com/repos/{gh_repo}/releases/latest")
    return json.loads(body)["tag_name"].lstrip("v")


def artifacts_published(url_tmpl, v):
    """Binaries land on artifacts.chirpstack.io separately from the GitHub release."""
    for arch in ("amd64", "arm64"):
        try:
            http(url_tmpl.format(v=v, arch=arch), method="HEAD")
        except urllib.error.HTTPError:
            return False
    return True


def git(cmd, check=True):
    return subprocess.run(f"git {cmd}", shell=True, check=check,
                          capture_output=True, text=True).stdout.strip()


files = {}  # path -> new content; written only on a real run


def edit(path, fn):
    path = f"{ADDON}/{path}"
    if path not in files:
        with open(path) as f:
            files[path] = f.read()
    files[path] = fn(files[path])


def replace_version(s, old, new):
    # Whole version token only: "4.1.2" must not match inside "4.1.20" or "14.1.2".
    return re.sub(rf"(?<![\d.]){re.escape(old)}(?!\d)", new, s)


with open(f"{ADDON}/Dockerfile") as f:
    dockerfile = f.read()
current = {a: re.search(rf"^ARG {a}=(\S+)$", dockerfile, re.M).group(1) for a in UPSTREAM}
new = {a: latest(spec[0]) for a, spec in UPSTREAM.items()}
for a in UPSTREAM:
    print(f"{UPSTREAM[a][1]}: current {current[a]}, latest {new[a]}")
changed = [a for a in UPSTREAM if new[a] != current[a]]
if not changed:
    print("Already up to date.")
    sys.exit(0)

# ponytail: if either changed upstream lacks binaries, wait for tomorrow's run
# rather than opening a partial bump. Artifacts usually trail the release by hours.
for a in changed:
    if not artifacts_published(UPSTREAM[a][2], new[a]):
        print(f"{UPSTREAM[a][1]} {new[a]} is released but not on artifacts.chirpstack.io yet; retrying tomorrow.")
        sys.exit(0)

with open(f"{ADDON}/config.json") as f:
    old_ver = json.load(f)["version"]
if "CHIRPSTACK_VERSION" in changed:
    new_ver = new["CHIRPSTACK_VERSION"]
else:  # only the bridge moved: add-on version = chirpstack version + bumped suffix
    base, _, n = old_ver.partition("-")
    new_ver = f"{base}-{int(n or 1) + 1}"
branch = f"bump/{new_ver}"
print(f"Add-on version {old_ver} -> {new_ver}")

if git(f"ls-remote --heads origin {branch}", check=False):
    print(f"Branch {branch} already exists on the remote; PR already opened. Nothing to do.")
    sys.exit(0)

for a in changed:
    for path in ("Dockerfile", "config.json", "README.md", "DOCS.md"):
        edit(path, lambda s: replace_version(s, current[a], new[a]))
edit("config.json", lambda s: re.sub(r'"version": "[^"]+"', f'"version": "{new_ver}"', s, count=1))
notes = "".join(
    f"- {UPSTREAM[a][1]} {current[a]} -> {new[a]} "
    f"([release notes](https://github.com/{UPSTREAM[a][0]}/releases/tag/v{new[a]}))\n"
    for a in changed
)
edit("CHANGELOG.md", lambda s: s.replace("# Changelog\n\n", f"# Changelog\n\n## {new_ver}\n\n{notes}\n", 1))

if dry_run:
    print("Pull request run; nothing written. Diff:")
    for path, content in files.items():
        with open(path) as f:
            before = f.read().splitlines(keepends=True)
        sys.stdout.writelines(difflib.unified_diff(before, content.splitlines(keepends=True), path, path))
    sys.exit(0)

for path, content in files.items():
    with open(path, "w") as f:
        f.write(content)

git("config --local user.name 'GitHub Actions'")
git("config --local user.email 'actions@github.com'")
git(f"checkout -b {branch}")
git(f"add {ADDON}")
git(f'commit -m "Bump ChirpStack add-on to {new_ver}"')
git(f"push origin {branch}")

body = f"""Automated bump `{old_ver}` -> `{new_ver}`.

{notes}
**Before merging:**
- Read the upstream release notes for changes to `chirpstack.toml` keys or the region files; `run.sh` generates both.
- Confirm the CI build and smoke test pass on this PR.

Opened by the update-check workflow.
"""
status, resp = http(
    f"https://api.github.com/repos/{repo}/pulls", method="POST",
    data=json.dumps({"title": f"Bump ChirpStack add-on to {new_ver}", "body": body,
                     "head": branch, "base": "master"}).encode(),
)
print(f"PR opened: {json.loads(resp)['html_url']}")
