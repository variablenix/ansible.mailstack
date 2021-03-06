# Arch Linux: Mailstack Deployment

This Playbook uses mail roles to automate the installation and configuration of mail services for [Arch Linux](https://www.archlinux.org/) servers. The end result is an idempotent virtual mail environment. The Playbook is intended to be used with an OpenLDAP backend for authentication.

#### Example Mail Structure
| IMAP | SMTP | LDAP | Policyd-SPF | PWhois Milter | OpenDKIM  | OpenDMARC   | SpamAssassin | ClamAV    | CyrusSASL |
|:----:|:----:|:----:|:-----------:|:-------------:|:---------:|:-----------:|:------------:|:---------:|:---------:|
|   a  |   a  |   a  |      a      |       a       |     a     |      a      |      a       |      a    |      a    |
|   b  |   b  |   b  |      b      |       b       |     b     |      b      |      b       |      b    |      b    |
|      |   c  |   c  |      c      |       c       |     c     |      c      |      c       |      c    |      c    |

### Pretasks
* Add a virtual mail user and group named `vmail`
* Ensure mail log directory exists
* Sync pacman package database
* Add `aur_builder` sudo user for AUR package builds
* Ensure UFW is installed for traffic management

The default UFW policy is set to DENY and both the Postfix (25,587) and Dovecot (143,993) roles forward their respective ports. The Pyzor task used with the SpamAssassin role forwards UDP port 24441 needed for [spam reports](https://pyzor.readthedocs.io/en/release-1-0-0/client.html).

### Roles
* [postfix](https://www.archlinux.org/packages/extra/x86_64/postfix/)
* [postgrey](https://www.archlinux.org/packages/community/any/postgrey/)
* [policyd-spf](https://aur.archlinux.org/packages/python-postfix-policyd-spf/)
* [pwhois_milter](https://aur.archlinux.org/packages/pwhois_milter/)
* [opendkim](https://www.archlinux.org/packages/community/x86_64/opendkim/)
* [opendmarc](https://www.archlinux.org/packages/community/x86_64/opendmarc/)
* [spamassassin](https://www.archlinux.org/packages/extra/x86_64/spamassassin/)
* [clamav](https://www.archlinux.org/packages/extra/x86_64/clamav/)
* [dovecot](https://www.archlinux.org/packages/community/x86_64/dovecot/)
* [solr](https://aur.archlinux.org/packages/solr/)
* [saslauthd](https://www.archlinux.org/packages/extra/x86_64/cyrus-sasl/)
* [automx](https://github.com/sys4/automx/)

#### Arch User Repository (AUR)
The [ansible-aur](https://github.com/kewlfft/ansible-aur) module is used for AUR package installs. As noted from the module's README.
> While Ansible expects to SSH as root, AUR helpers do not allow executing operations as root, they all fail with "you cannot perform this operation as root". It is therefore recommended to create a user, that we will call for example aur_builder, that has no need for password with pacman in sudoers. This can be done in Ansible with the following actions:

## Deploying
### Prepare
Create the mailstack virtualenv.

`mkvirtualenv mailstack; pip install -r requirements.txt`

##### Run Mailstack Playbook with required Ansible Vault pass for decryption (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --ask-vault-pass`

##### Run specific Mailstack roles using tags (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --tags "postfix,postgrey"`

##### Run specific Mailstack configs for certain roles using tags (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --tags "postfixconfig,header_checks,doveconfig"`

### Postfix
The Postfix MTA is the first role this Playbook will deploy. The end result is a Postfix virtual mail environment with

* LDAP mailboxes
* LDAP mail aliases
* LDAP domains
* LDAP mail groups
* LDAP mail forwarding

Additional configurations of importance: [Postscreen](http://www.postfix.org/POSTSCREEN_README.html), [header checks](http://www.postfix.org/postconf.5.html#header_checks), [check_sender_access](http://www.postfix.org/postconf.5.html#check_sender_access), [SMTP header checks](http://www.postfix.org/postconf.5.html#smtp_header_checks) and various other MTA settings.

##### Tags
|       postfix      |
|:------------------:|
|    postfixconfig   |
|    header_checks   |
|    sender_access   |
| smtp_header_checks |
|     postscreen     |
|    postfix_ldap    |
|         ufw        |

### Postgrey
By default the Postfix role is configured to use Postgrey on port 10030 within the same host as Postfix. In addition to using Postscreen with Postfix, this role adds another line of defense against spammers. The role will install and configure a local whitelist for Postgrey clients and recipients that should not be greylisted.

##### Tags
|      postgrey      |
|:------------------:|
| postgrey_whitelist |

### Policyd-SPF
This role syncs our Postfix SPF policy configuration to all Postfix MTA hosts. The default Postfix role includes SPF policy checks.

##### Tags
| policyd-spf |
|:-----------:|
|     spf     |

### Pwhois Milter
The Prefix WhoIs Milter is a mail filter for Postfix to query Prefix WhoIs (whois.pwhois.org by default) about the originating IP address found in the final Received or X-Originating-IP mail headers. Note the Postfix role defines the PWhois headers in the Postfix `header_checks` file. By default Pwhois Milter listens on port 8472.

##### Tags
| pwhois |
|:------:|

### OpenDKIM
The OpenDKIM role will automate the following tasks for a multi-domain environment. Note by default OpenDKIM listens on port 8891 within the same host as Postfix.

* Install OpenDKIM
* Sync config and TrustedHosts
* Create domain directories
* Configure KeyTable and SigningTable for DKIM domains
* Generate signing key for domains if needed

Note that for DKIM to work a [TXT DNS record](https://support.dnsimple.com/articles/dkim-record/) is required for each DKIM domain.

#### Verify
1. `host -t TXT mail._domainkey.example.com`
2. [DKIM Core](https://dkimcore.org/tools/)

##### Tags
|    dkim     |
|:-----------:|
| dkimconfig  |

### OpenDMARC
The OpenDMARC role will install and sync our OpenDMARC configuration for all Postfix MTA hosts. The Postfix role includes the necessary DMARC configuration inside the `main.cf` file.

In order for DMARC to work note the following requirements for each mail domain served.

1. SPF TXT DNS record
2. OpenDKIM with a domain key TXT DNS record
3. DMARC TXT DNS record. See the [DMARC Guide](https://dmarcguide.globalcyberalliance.org/#/dmarc) for step by step assistance in configuring a DMARC TXT record

##### Tags
| opendmarc |
|:---------:|

### SpamAssassin
By default the Postfix role configures SpamAssassin to be used as a transport inside the `master.cf` file. This allows spamd to continuously process spam mail checks. The SpamAssassin role will perform several tasks such as enabling regular rule updates with a systemd timer and utilizing the ClamAV plugin in addition to configuring the following

* SpamAssassin config file
* SpamAssassin plugin config files 
* SpamAssassin whitelist/blacklist
* Razor/Pyzor/RBL

#### Bayesian SQL
The SpamAssassin role will create the Bayes database and user. The Bayes MySQL tables will be imported if they are not present.

##### Tags
|      spamd      |
|:---------------:|
|   spamdconfig   |
|      razor      |
|      pyzor      |
| spamd_whitelist |
| spamd_blacklist |
|    bayes_sql    |
|       ufw       |

### ClamAV
This role will install and configure ClamAV on each of our Postfix MTA hosts that SpamAssassin will also leverage using the ClamAV plugin. The ClamAV freshclam service is enabled and configured so virus definitions are always being updated. This role includes the [clamav-unofficial-sigs](https://aur.archlinux.org/packages/clamav-unofficial-sigs/) package for even more database signatures to check for.

##### Tags
| clamd |
|:-----:|

### Dovecot
The Dovecot role configures LDAP authentication using [password lookups](https://wiki.dovecot.org/AuthDatabase/LDAP/PasswordLookups) instead of the slower auth bind and also uses [dsync](https://wiki2.dovecot.org/Tools/Doveadm/Sync) for [replication](https://wiki.dovecot.org/Replication) between 2 IMAP hosts. Ansible Vault is used to encrypt and store the dsync replication password string in a variable named `doveadm_password`. The following can be used to create the encrypted variable string.

`ansible-vault encrypt_string 'secretpw' --name 'doveadm_password'`

Since the replication password is encrypted using Ansible Vault, passing `--ask-vault-pass` is required.

##### Run Playbook with Ansible Vault for dsync replication (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --ask-vault-pass`

##### Run role with Ansible Vault for dsync replication (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --ask-vault-pass --tags "dovecot"`

##### Run only for dsync replication config (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --ask-vault-pass --tags "doveconfig"`

#### Quota
Port 12340 is the default port used by quota and is also the same quota port defined for `check_policy_service` within the Postfix `main.cf` config file.

#### MailCrypt plugin
The default configuration used with this role uses the MailCrypt plugin defined in `10-mail.conf` to encrypt mail store files. The expected public and private [elliptic curve](https://wiki.dovecot.org/Plugins/MailCrypt#EC_key) keys default to the `/etc/dovecot/mcrypt` directory.

### LDAP
The supported LDAP mail attributes provisioned with this role require [postfix-book.schema](https://github.com/variablenix/ldap-mail-schema/blob/master/postfix-book.schema) to be loaded with an LDAP backend server such as OpenLDAP.

|       objectClass      | attributes               |
|:----------------------:|--------------------------|
| PostfixBookMailAccount | `mail`                   |
| PostfixBookMailForward | `mailAlias`              |
|                        | `mailHomeDirectory`      |
|                        | `mailStorageDirectory`   |
|                        | `mailUidNumber`          |
|                        | `mailGidNumber`          |
|                        | `mailEnabled`            |
|                        | `mailGroupMember`        |
|                        | `mailQuota`              |
|                        | `mailSieveRuleSource`    |
|                        | `mailForwardingAddress`  |

##### Tags
|    dovecot   |
|:------------:|
|  doveconfig  |
| dovecot_ldap |
|  dovemaster  |
|   dovecrypt  |
|      ufw     |

### Solr
The Dovecot role is configured to use the [Solr plugin](https://wiki.dovecot.org/Plugins/FTS/Solr) for full text search indexing. The Solr role will install, configure and create the Dovecot core if it does not already exist. The default managed schema will be replaced with our Dovecot schema if it is not already loaded.

##### Tags
| solr |
|:----:|
| solrcron |

### CyrusSASL
This simple role will install [cyrus-sasl](https://www.archlinux.org/packages/extra/x86_64/cyrus-sasl/) and configure SASL to use LDAP with TLS.

##### Tags
| sasl |
|:----:|

### AutoMX
The [automx](https://github.com/sys4/automx) role uses `ldap` as the default backend, but can instead be changed to `static`. Apache is the HTTP server used with this role and will configure the necessary automx virtualhost configs for any number of domains. DNS must be configured for each domain that will be using automx. See the [DNS Configuration](https://github.com/sys4/automx/blob/master/INSTALL) section for more info. 

The following automx man pages are available.
* `automx-test`
* `automx.conf`
* `automx_ldap`
* `automx_script`
* `automx_sql`

##### Tags
|    automx   |
|:------------:|


### TO DO
* Roundcubemail
* OpenLDAP
