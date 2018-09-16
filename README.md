# Arch Linux: Mailstack Deployment

This Playbook uses mail roles to automate the installation and configuration of mail services for [Arch Linux](https://www.archlinux.org/) servers.

#### Mail Structure
| IMAP | SMTP | LDAP | Policyd-SPF | PWhois Milter | OpenDMARC | SpamAssassin | ClamAV     | CyrusSasl |
|:----:|:----:|:----:|:-----------:|:-------------:|:---------:|:------------:|:----------:|:---------:|
|   a  |   a  |   a  |      a      |       a       |     a     |      a       |      a     |      a    |
|   b  |   b  |   b  |      b      |       b       |     b     |      b       |      b     |      b    |
|      |   c  |   c  |      c      |       c       |     c     |      c       |      c     |      c    |

### Roles
* [postfix](https://www.archlinux.org/packages/extra/x86_64/postfix/)
* [postgrey](https://www.archlinux.org/packages/community/any/postgrey/)
* [policyd-spf](https://aur.archlinux.org/packages/python-postfix-policyd-spf/)
* [pwhois_milter](https://aur.archlinux.org/packages/pwhois_milter/)
* [opendmarc](https://www.archlinux.org/packages/community/x86_64/opendmarc/)
* [spamassassin](https://www.archlinux.org/packages/extra/x86_64/spamassassin/)
* [clamav](https://www.archlinux.org/packages/extra/x86_64/clamav/)
* [dovecot](https://www.archlinux.org/packages/community/x86_64/dovecot/)
* [solr](https://aur.archlinux.org/packages/solr/)
* [saslauthd](https://www.archlinux.org/packages/extra/x86_64/cyrus-sasl/)

#### Arch User Repository (AUR)
The [makepkg](https://github.com/gunzy83/ansible-makepkg) Ansible module is used for AUR package installs.

## Deploying
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

Other configurations include Postscreen, header checks, sender access, SMTP header checks and many more MTA settings.

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
##### Tags
|      postgrey      |
|:------------------:|
| postgrey_whitelist |

By default the Postfix role is configured to use Postgrey. In addition to using Postscreen with Postfix, this role adds another line of defense against spammers. The role will install and configure a local whitelist for Postgrey clients and recipients that should not be greylisted. 

### Policyd-SPF
##### Tags
| policyd-spf |
|:-----------:|
|     spf     |

This role syncs our Postfix SPF policy configuration to all Postfix MTA hosts. The default Postfix role includes SPF policy checks.

### Pwhois Milter
##### Tags
| pwhois |
|:------:|

The Prefix WhoIs Milter is a mail filter for Postfix to query Prefix WhoIs (whois.pwhois.org by default) about the originating IP address found in the final Received or X-Originating-IP mail headers. By default the Postfix role defines the PWhois headers in the Postfix `header_checks` file.

### OpenDMARC
##### Tags
| opendmarc |
|:---------:|

The OpenDMARC role will install and sync our OpenDMARC configuration for all Postfix MTA hosts. The Postfix role includes the necessary DMARC configuration inside the `main.cf` file.

In order for DMARC to work note the following requirements for each mail domain served.

1. SPF TXT DNS record
2. OpenDKIM with a domain key TXT DNS record
3. DMARC TXT DNS record. See the [DMARC Guide](https://dmarcguide.globalcyberalliance.org/#/dmarc) for step by step assistance in configuring a DMARC TXT record

### SpamAssassin
##### Tags
|      spamd      |
|:---------------:|
|   spamdconfig   |
|      razor      |
|      pyzor      |
| spamd_whitelist |
| spamd_blacklist |
|       ufw       |

By default the Postfix role configures SpamAssassin to be used as a transport inside the `master.cf` file. This allows spamd to continuously process spam mail checks. The SpamAssassin role will perform several tasks such as enabling regular rule updates with a systemd timer and utilizing the ClamAV plugin in addition to configuring the following

* SpamAssassin config file
* SpamAssassin plugin config files 
* SpamAssassin whitelist/blacklist
* Razor/Pyzor/RBL

to do: MariaDB/MySQL config for Bayes database

### ClamAV
##### Tags
| clamd |
|:-----:|

This role will install and configure ClamAV on each of our Postfix MTA hosts that SpamAssassin will also leverage using the ClamAV plugin. The ClamAV freshclam service is enabled and configured so virus definitions are always being updated. This role includes the [clamav-unofficial-sigs](https://aur.archlinux.org/packages/clamav-unofficial-sigs/) package for even more database signatures to check for.

### Dovecot
##### Tags
|    dovecot   |
|:------------:|
|  doveconfig  |
| dovecot_ldap |
|      ufw     |

This Playbook makes use of Ansible Vault to encrypt and store our dsync replication password string in a variable named `doveadm_password`. The following can be used to create the encrypted variable string.

`ansible-vault encrypt_string 'secretpw' --name 'doveadm_password'`

#### Replication
By default this role uses [dsync](https://wiki2.dovecot.org/Tools/Doveadm/Sync) for [replication](https://wiki.dovecot.org/Replication) between 2 Dovecot hosts. The role makes use of Ansible Vault to encrypt and store our dsync replication password string in a variable named `doveadm_password`. The following can be used to create the encrypted variable string.

`ansible-vault encrypt_string 'secretpw' --name 'doveadm_password'`

Since replication password is encrypted using Ansible vault, passing `--ask-vault-pass` is required.

##### Run Playbook with Ansible Vault for dsync replication (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --ask-vault-pass`

##### Run role with Ansible Vault for dsync replication (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --ask-vault-pass --tags "dovecot"`

##### Run only for dsync replication config (verify with check-diff mode first)
`ansible-playbook main.yml --check --diff --ask-vault-pass --tags "doveconfig"`

#### MailCrypt plugin
The default configuration used with this role uses the MailCrypt plugin defined in `10-mail.conf` to encrypt mail store files. The expected public and private [elliptic curve](https://wiki.dovecot.org/Plugins/MailCrypt#EC_key) keys default to the `/etc/dovecot/mcrypt` directory. Both the private and public key files should be encrypted using Ansible Vault and `--ask-vault-pass` passed for the required decryption.

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

### Solr
##### Tags
| solr |
|:----:|

The Dovecot role is configurd to use the [Solr plugin](https://wiki.dovecot.org/Plugins/FTS/Solr) for full text search indexing.

### CyrusSasl
##### Tags
| sasl |
|:----:|



### TO DO
* AutoMX
* OpenDKIM

