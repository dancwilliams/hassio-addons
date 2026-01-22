# Home Assistant Add-on: Monerod

## About

Cet Addon vous permettra l'execution d'un noeud [Monerod][getmonero] sur votre
HomeAssistant sur RaspBerry Pi 4.

## Installation

D'habord ajoutez le repertoire à l'add-on store de HomeAssistant (`https://github.com/casse-boubou/hassio-addons`):

[![Open your Home Assistant instance and show the add add-on repository dialog
with a specific repository URL pre-filled.][add-repo-shield]][add-repo]

Ensuite recherchez Monerod dans le store et cliquez sur installer:

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.][add-addon-shield]][add-addon]

## Configuration

Example add-on configuration:

```yaml
monerod_conf_overrides:
  - property: out-peers
    value: "64"
data_dir: bitmonero_folder_pruned
prune_blockchain: true
sync_pruned_blocks: true
db_sync_mode: safe
```

**Note**: _Ceci n'est qu'un exemple, ne le copier-coller pas ! Crée le votre!_

### Option: `monerod_conf_overrides` (optional)

Cette option vous permet de fournir une option de configuration pour personnaliser
les configutaions avancées de Monerod qui n'ont pas été prédéfinit en tant qu'options
d'addon paramétrable.

Vous pouvez voir l'ensemble complet des options disponibles ici :

<https://monerodocs.org/interacting/monerod-reference/#options>

**Syntax**:

```conf_syntax
- property: option-name
  value: "value"
OR
- property: valueless-option-name
  value: ""     **for options that don't expect value**
```

**Note**: _Toutes les options n'ont pas été testées. La modification de ces options
peut éventuellement entraîner des problèmes avec votre instance.
À UTILISER À VOS RISQUES ET PÉRILS!_

Celles-ci sont sensibles à la casse. Vous pouvez consulter la
[configuration par défaut][default-config] que cet add-on utilise.

### Option: `data_dir` (required)

Chemin d'accès complet au répertoire de données. C'est là que la blockchain, les
fichiers LOG et la mémoire du réseau p2p sont stockés. Il prend racines depuis le
dossier 'media' du HomeAssistant. Quelques détails supplémentaire [ici][datadir]

### Option: `max_log_file_size` (optional)

Limite de taille en octets du fichier LOG (=104850000 par défaut, soit un peu moins
de 100 Mo). Une fois que le fichier journal dépasse cette limite, monerod crée le
fichier journal suivant avec un suffixe d'horodatage UTC -YYYY-MM-DD-HH-MM-SS.

Dans les déploiements de production, vous préféreriez probablement utiliser une
solutions comme logrotate à la place. Dans ce cas, définissez `max_log_file_size`
sur 0 pour empêcher monerod de gérer les fichiers journaux.

### Option: `prune_blockchain` (optional)

La blockchain Prune permet d'économiser 2/3 de l'espace disque sans dégrader les
fonctionnalités. Pour un effet maximal, cela devrait déjà être activé lors de la
première synchronisation. Si vous ajoutez cette option plus tard, les données déja
synchronisées ne seront élaguées que logiquement sans réduire la taille du fichier
de la blockchain et le gain de place minime.

L'inconvénient est que vous contribuerez moins au réseau Monero P2P en termes d'aide
à la synchronisation des nouveaux nœuds (jusqu'à 1/8 de la contribution normale).
Cependant, vous serez toujours utile pour relayer de nouvelles transactions et de
nouveaux blocs.

### Option: `sync_pruned_blocks` (optional)

Acceptez la synchronisation depuis des noeuds deja Pruned au lieu que monerod le
fasse lui même. Il devrait économiser le transfert réseau lorsqu'il est utilisé
avec `prune_blockchain`.

### Option: `db_sync_mode` (optional)

Spécifiez le mode de synchronisation. [safe|fast|fastest]

La valeur par défaut est safe.

Le mode fast peut corrompre la base de données blockchain en cas de plantage du système.
Il ne devrait pas corrompre si seul monerod plante. Si vous êtes préoccupé par les
plantages du système, utilisez le mode safe.

## Changelog & Releases

Vous pouvez consulter le changelog [GitHub ici][releases].

## Support

Je ne suis pas dévellopeur, n'ai aucune formation de code, je suis simplement autodidact.
Si vous avez une question concernant HA et ses add-ons vous pouvez consulter:

- [Le Forum communautaire francophone][hacf] de HomeAssistant
- [Le Forum communautaire anglophone][forum] de HomeAssistant.
- [Le serveur Discord][discord-ha] de HomeAssistant.

## License

MIT License

Copyright (c) 2022-2025 [Frosh][Frosh]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

> **_Parts of the project are originally Copyright (c) 2014-2023, [The Monero Project][themoneroproject],
> distributed under [licence][monerolicense]:_**
>
> Redistribution and use in source and binary forms, with or without modification,
> are permitted provided that the following conditions are met:
>
> > _1. Redistributions of source code must retain the above copyright notice, this
> > list of conditions and the following disclaimer._
> >
> > _2. Redistributions in binary form must reproduce the above copyright notice,
> > this list of conditions and the following disclaimer in the documentation and/or
> > other materials provided with the distribution._
> >
> > _3. Neither the name of the copyright holder nor the names of its contributors
> > may be used to endorse or promote products derived from this software without
> > specific prior written permission._
> >
> > _THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
> > AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
> > WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
> > DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
> > FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
> > DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
> > SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
> > CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
> > OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
> > OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE._

[add-addon]: https://my.home-assistant.io/redirect/supervisor_addon/?addon=c751e21a_monerod
[add-addon-shield]: https://my.home-assistant.io/badges/supervisor_addon.svg
[add-repo]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fcasse-boubou%2Fhassio-addons
[add-repo-shield]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[discord-ha]: https://discord.gg/c5DvZ4e
[forum]: https://community.home-assistant.io
[hacf]: https://forum.hacf.fr/
[Frosh]: https://github.com/casse-boubou
[releases]: https://github.com/casse-boubou/addon-monerod/releases
[getmonero]: https://www.getmonero.org/
[datadir]: https://monerodocs.org/interacting/overview/#data-directory
[themoneroproject]: https://github.com/monero-project
[monerolicense]: https://github.com/monero-project/monero/blob/master/LICENSE
[default-config]: https://github.com/casse-boubou/addon-monerod/blob/main/monerod/rootfs/etc/monerod/bitmonero.conf
