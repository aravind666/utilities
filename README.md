utilities
=========

This is a ruby command line application to migrate managed content from crossroads legacy system to milacron codebase . 


Installation 
============

Install ruby 2.0.0 or latest version in your system . 

To use this application just run these commands to install gems

```
gem install bundler
bundle install
```


Configuration 
=============

All required configuration has been maintained in config/global.conf file . A sample of the same has been provided inside config directory
`global.conf.sample`

Please follow the comments carefully and update as per your local environment .
you can copy the contents and create global.conf file or you can also rename the global.conf.sample
to global.conf .

Execution 
=========

 To know the available utiilites just run

 $ ruby march.rb

 you will be prompted with the list of arguments that you can pass . Just pass what ever you require.

Utilities and its Uses
=======================

 crawl-for-links : - Crawls and generate logs of broken links in the specified list
 copy-media : - Copies required media to appropriate folders
 migrate_content : - Migrates managed content from legacy
 migrate_audios : - Migrate audio posts from legacy
 migrate_videos : - Migrate video posts from legacy
 migrate-messages : - Migrate message posts from legacy
 migrate-blog : - Migrate blog posts from legacy
 migrate-dynamic-content : - Migrate dynamic ( php files serving only content )  posts from legacy


Logging 
=======

Considerable amount of logging has been added in most of the rescue blocks , Errors and warnings are logged in migration.log file. which gets generated from the script . 



