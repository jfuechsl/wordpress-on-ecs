#!/bin/bash

cd /www
if ! [ -e index.php -a -e wp-includes/version.php ]; then
  echo >&2 "WordPress not found in $PWD - copying now..."
  tar --create \
			--file - \
			--one-file-system \
			--directory /usr/src/wordpress \
			--owner "www-data" --group "www-data" \
			. | tar --extract --file -
	echo >&2 "Complete! WordPress has been successfully copied to $PWD"
fi
