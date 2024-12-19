# vim: set ft=make :

setup-luks-fido2-unlock:
	#!/usr/bin/bash
	sudo /usr/libexec/luks-enable-fido2-unlock

remove-luks-fido2-unlock:
	#!/usr/bin/bash
	sudo /usr/libexec/luks-disable-fido2-unlock