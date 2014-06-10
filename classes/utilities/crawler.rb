# crawler class which defines various attributes and behaviours which are used in
# crawling site
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Instantiating this class leads to crawl
#
class Crawler

  #
  # starts crawling
  #
  def initialize
    File.delete('links_broken.log') if File.exist?('links_broken.log');
    self.crawl_milacron();
  end

  #
  # Start crawling the site
  #
  def crawl_milacron
    links_to_crawl = Crawlhelper.get_links_to_crawl();
    response_hash = Crawlhelper.get_first_level_links_from_response_by_crawling(links_to_crawl);
    href_hash = self.process_each_url_for_links(response_hash);
    self.log_hrefs_crawled(href_hash);
    abort("Completed crawling the URL please check log files");
  end

  #
  # This method will get the URLs in the response body of each links
  #
  def process_each_url_for_links(response_hash)
    href_hash = Hash.new;
    response_hash.each do |link, href_list|
      href_list.each do |href|
        href = Immutable.baseURL + href;
        response = Crawlhelper.get_response_from_url(href);
        href_hash[href] = Crawlhelper.get_links_within_response_body(response);
      end
    end
    return href_hash;
  end

  #
  # This method logs each hrefs based on classification
  #
  def log_hrefs_crawled(href_hash)
    log_message = '';
    href_hash.each do |link, href_list|
      log_message += "\n URL : -  #{link} \n";
      broken_links = '';
      href_list.each do |href|
        broken_links = "Broken links : - "
        href.gsub('http://www.crossroads.net/', '/');
        if href['http://'] || href['https://'] || href['itpc://'] || href['mailto:'] || href['.jpg']
          Immutable.log.info " - > #{ href } -- we do not to do any thing with this since its external   ";
        elsif href['/tags/']
          Immutable.log.info " - > #{ href } -- we do not to do any thing with this since its tags link in the right nav";
        elsif href[/^#.+/]
          Immutable.log.info " - > #{ href } -- we do not need this since it is just hash tag";
        elsif href['.php']
          broken_links += href + "\n";
        elsif href['mysend/']
          broken_links += href + "\n";
        elsif !href.empty?
          broken_links += href + "\n";
        end
      end
      if !broken_links.empty?
        log_message += broken_links
        File.open("links_broken.log", 'a+') { |f| f.write(log_message + "\n") }
      end
    end
  end
end
