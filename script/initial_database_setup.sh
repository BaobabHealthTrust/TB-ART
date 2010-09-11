#!/bin/bash

set -v # will echo all of the scripts command to the screen

# DB_USER="root --password=XXX"
DB_USER="root -ppassword"
DB="mateme_development"
DB_test="mateme_test"
SITE="nno"
RAILS_ENV="development"

echo "DROP DATABASE $DB;CREATE DATABASE $DB;" | mysql -u $DB_USER

if [ ! -x config/database.yml ] ; then
  cp config/database.yml.example config/database.yml
fi

mysql -u $DB_USER $DB < db/schema.sql
mysql -u $DB_USER $DB < db/migrate/alter_global_property.sql
mysql -u $DB_USER $DB < db/migrate/create_sessions.sql
mysql -u $DB_USER $DB < db/migrate/create_weight_for_heights.sql
mysql -u $DB_USER $DB < db/migrate/create_weight_height_for_ages.sql

#rake openmrs:bootstrap:load:defaults RAILS_ENV=production
#rake openmrs:bootstrap:load:site SITE=$SITE RAILS_ENV=production
rake openmrs:bootstrap:load:defaults 
rake openmrs:bootstrap:load:site SITE=$SITE
#rake db:fixtures:load
