utilities
=========

This is a ruby command line application to migrate managed content from crossroads legacy system to milacron codebase . 


Installation 
============

Install ruby 2.0.0 or latest version in your system . 

To use this application just run these commands to install gems

gem install bundler
bundle install



Configuration 
=============

All required configuration has been maintained in config/global.conf file . You just need to update the details as per your environment . 
Below are the details related to configuration 

```
# Specify DB credentials and host name 
db_user_name = root
db_password = root
db_name = crossroadsdotnet
db_host = localhost

# Mention the relative paths of source and destination 
content_source_path = ../cms/production_content/
content_destination_path = ../cms/content
```


Execution 
=========

To migrate content just run 
```
ruby march.rb migrate-content 
```

Logging 
=======

Considerable amount of logging has been added in most of the rescue blocks , Errors and warnings are logged in migration.log file. which gets generated from the script . 



