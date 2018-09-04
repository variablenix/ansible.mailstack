# Arch Linux: Mailstack Deployment

This Playbook uses mail roles to automate the installation and configuration of mail services. There are 3 MX hosts used with this mail environment.

### Roles
* [postfix](https://www.archlinux.org/packages/extra/x86_64/postfix/)
* [postgrey](https://www.archlinux.org/packages/community/any/postgrey/)
* [policyd-spf](https://aur.archlinux.org/packages/python-postfix-policyd-spf/)
* [pwhois_milter](https://aur.archlinux.org/packages/pwhois_milter/)
* [opendmarc](https://www.archlinux.org/packages/community/x86_64/opendmarc/)
* [dovecot](https://www.archlinux.org/packages/community/x86_64/dovecot/)
* [saslauthd](https://www.archlinux.org/packages/extra/x86_64/cyrus-sasl/)

#### Arch User Repository (AUR)
The [makepkg](https://github.com/gunzy83/ansible-makepkg) Ansible module is used for AUR package installs

#### Run Mailstack Playbook in check-diff mode
```
ansible-playbook -i inventory/all.inv main.yml --check --diff
```
#### Run Specific Mailstack role using tags in check-diff mode
```
ansible-playbook -i inventory/all.inv main.yml --check --diff --tags "a,b,c"
```
#### Tags
| postfix | postgrey | policyd-spf | pwhois_milter | opendmarc | dovecot | saslauthd   |
|--------------------|----------|---|---|---|---|---|
| postfix            | postgrey           | policyd-spf | pwhois | opendmarc | dovecot      | saslauthd  |
| postfixconfig      | postgrey_whitelist | spf         |        |           | doveconfig   |
| header_checks      |                    |             |        |           | dovecot_ldap
| sender_access      |
| smtp_header_checks
| postfix_ldap

#### Run Mailstack Playbook
```
ansible-playbook -i inventory/all.inv main.yml --diff
```

### Dovecot
This Playbook makes use of Ansible Vault to encrypt and store our dsync replication password string in a variable named `doveadm_password`

`ansible-vault encrypt_string 'secretpw' --name 'doveadm_password'`

#### Run Mailstack Playbook with Vault for dsync replication
```
ansible-playbook -i inventory/all.inv main.yml --diff --ask-vault
```
#### MailCrypt plugin
The default configuration used with this Playbook uses the MailCrypt plugin defined in `10-mail.conf` to encrypt mail store files. The expected public and private [elliptic curve](https://wiki.dovecot.org/Plugins/MailCrypt#EC_key) keys default to the `/etc/dovecot/mcrypt` directory. Both the private and public key files should be encrypted using Vault and `--ask-vault` passed with Playbook

### LDAP
The supported LDAP mail attributes provisioned with this Playbook require [postfix-book.schema](https://github.com/variablenix/ldap-mail-schema/blob/master/postfix-book.schema) to be loaded with an LDAP backend server such as OpenLDAP

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


### TO DO
* AutoMX
* OpenDKIM
* SpamAssassin
* ClamAV
