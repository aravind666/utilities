# encoding: ASCII-8BIT

# Crawl Helper class definition, which defines several helper
# classes for crawling urls
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# All behaviours exhibitted here are selfies you donot need an object to call them
#
#

class Crawlhelper
  class << self

    #
    # This method returns the links to crawl from crawl sitemap list ,
    # As an array
    #
    def get_links_to_crawl

      file_with_crawl_links = Immutable.config.crawl_links_list;
      list_of_links_to_crawl = []
      File.open(file_with_crawl_links) do |links|
        links.each do |link|
          list_of_links_to_crawl << link.to_s;
        end
      end
      return list_of_links_to_crawl;
    end

    #
    # This method returns the first level response body from the crawl URL ,
    # In the form of hash where key is the crawled link and
    # value is the Urls list .
    #
    def get_first_level_links_from_response_by_crawling(links_to_crawl)
      response_hash = Hash.new
      links_to_crawl.each do |link|
        link = link.gsub("\n",'');
        crawler = Mechanize.new;
        response = Crawlhelper.get_response_from_url(link);
        response_hash[link] = get_links_within_response_body(response);
      end
      return response_hash;
    end

    #
    # This method gets the response body of the URL passed
    #
    def get_response_from_url(link)
      begin
        crawler = Mechanize.new
        response = crawler.get(link);
        return response;
      rescue Mechanize::ResponseCodeError => exp
        Immutable.log.error "URL - #{content_url} Error details #{exp.inspect}";
        return false;
      end
    end

    #
    # This method gets the response body of the URL passed
    # To parse and process
    #
    def get_response_body_to_crawl(response_body)
      if response_body.search('div#container').nil?
        body_to_parse = response.search('body');
      else
        body_to_parse = response.search('div#container');
      end
      return body_to_parse;
    end

    #
    # This method will parse the responsebody
    # and returns links which exists there
    #
    def get_links_within_response_body(body_to_parse)
      hrefs_list = [];
      body_to_parse.parser.css('a').each do |a|
        href = a.attribute('href').to_s;
        hrefs_list << href
      end
      return hrefs_list;
    end

    #
    # This method will process response hash
    # which was created by get_first_level_response_by_crawling
    # each key in the response hash is a url
    # each value is an Nokogiri Mechanize page object
    #
    def process_response_of_each_url

    end


  end
end