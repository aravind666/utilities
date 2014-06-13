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
    # * get the links that needs to be crawled
    # * opens each of the link and convert to string
    # * and returns the list
    #
    # crawlhelper.get_links_to_crawl
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
    # * for each new line
    # * checks for the anchor tag href response and list them
    # * returns the link back
    #
    # crawlhelper.get_first_level_links_from_response_by_crawling('string links')
    #
    def get_first_level_links_from_response_by_crawling(links_to_crawl)
      response_hash = Hash.new
      links_to_crawl.each do |link|
        link = link.gsub("\n", '');
        crawler = Mechanize.new;
        response = Crawlhelper.get_response_from_url(link);
        response_hash[link] = get_links_within_response_body(response);
      end
      return response_hash;
    end

    #
    # This method gets the response body of the URL passed
    #
    # * get the response from the link
    # * and log them on error with the error response
    #
    # crawlhelper.get_response_from_url('string link')
    #
    def get_response_from_url(link)
      begin
        crawler = Mechanize.new
        response = crawler.get(link);
        return response;
      rescue Mechanize::ResponseCodeError => exp
        Immutable.log.error "URL - #{link} Error details #{exp.inspect}";
        return false;
      end
    end

    #
    # This method gets the response body of the URL passed
    # To parse and process
    #
    # * check the response from the particular div with id container
    # * if doesn't exists then search in the body
    #
    # crawlhelper.get_response_body_to_crawl('string')
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
    # * for each anchor tag get the href associated to it
    #
    # crawlhelper.get_links_within_response_body('string')
    #
    def get_links_within_response_body(body_to_parse)
      hrefs_list = [];
      body_to_parse.parser.css('a').each do |a|
        href = a.attribute('href').to_s;
        hrefs_list << href
      end
      return hrefs_list;
    end

  end
end