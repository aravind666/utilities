# encoding: ASCII-8BIT

# message class which defines various attributes and behaviours which are used in
# message migration
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
#
# Instiating this class leads to copying each required file to respective folders
#

class Copy

  #
  # Create Message object by initilizing the migration flow
  #
  def initialize
    self.copy_media();
  end

  #
  # This method initiates copying
  #
  def copy_media
    begin

      self.setup_folders_required();
      self.copy_content_media_references();
      self.copy_dynamic_content_media_references();
      self.copy_message_media_references();
      self.copy_audio_post_media_references();
      self.copy_video_post_media_references();
    end
  end

  #
  # This method creates required directory
  # It also clears the directories to freshly migrate things
  #
  def setup_folders_required
    dirlist = ['doc', 'png', 'jpg', 'jpeg', 'gif', 'pdf', 'mp3', 'flv', 'mp4', 'all'];
    dirlist.each do |dirname|
      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname);
      end
      FileUtils.rm_rf(Dir.glob("#{dirname}/*"));
    end
  end

  #
  # This method copies all message media references to
  # it appropriate folders
  #
  def copy_message_media_references()
    message_media_data = Mediahelper.get_all_media_from_all_messages();
    self.process_media_data(message_media_data);
    puts "Completed copying message post media elements";
  end

  #
  # This method copies all audio posts media references to
  # it appropriate folders
  #
  def copy_audio_post_media_references()
    audio_data = Mediahelper.get_audio_content();
    self.process_media_data(audio_data);
    puts "Completed copying audio post media elements";
  end

  #
  # This method copies all video posts media references to
  # it appropriate folders
  #
  def copy_video_post_media_references()
    video_data = Mediahelper.get_media_content();
    self.process_media_data(video_data);
    puts "Completed copying video post media elements";
  end

  #
  # This method copies all dynamic content  posts media references to
  # it appropriate folders
  #
  def copy_dynamic_content_media_references
    links_to_migrate = Contenthelper.get_dynamic_links_to_migrate();
    self.process_parse_dynamic_content(links_to_migrate);
  end


  #
  # This method copies all content media references to
  # it appropriate folders
  #
  def copy_content_media_references
    content_data = Contenthelper.get_content_from_database();
    self.parse_content(content_data);
    puts "Completed copying content media";
  end


  #
  # This method processes media data
  # by collecting the things required to
  # migrate
  #
  def process_media_data(message_media_data)
    message_media_data.each do |media|
      lqpath = media['LowQFilePath'];

      if !lqpath['s3.amazonaws.com']
        file = media['LowQFilePath'] + media['HighQFilePath'];
        file.gsub('http://www.crossroads.net/', '/');
        file.gsub('https://www.crossroads.net/', '/');
        self.copy_files_to_appropriate_folders(file);
      end

      status = false
      thumbnail = media['ThumbImagePath'];
      if (File.file?(Immutable.config.legacy_htdocs_path+"/players/media/smallThumbs/" + thumbnail))
        status = true;
        thumbnail_path = Immutable.config.legacy_htdocs_path + "/players/media/smallThumbs/" + thumbnail;
      elsif (File.file?(Immutable.config.legacy_htdocs_path + "/players/media/mediumHz/" + thumbnail))
        status = true;
        thumbnail_path = Immutable.config.legacy_htdocs_path + "/players/media/mediumHz/" + thumbnail;
      elsif (File.file?(Immutable.config.legacy_htdocs_path+"/uploadedfiles/" + thumbnail))
        status = true;
        thumbnail_path = Immutable.config.legacy_htdocs_path+"/uploadedfiles/" + thumbnail;
      elsif (File.file?(Immutable.config.legacy_htdocs_path+"/images/uploadedImages/" + thumbnail))
        status = true;
        thumbnail_path = Immutable.config.legacy_htdocs_path+"/uploadedfiles/" + thumbnail;
      end
      if status?
        self.copy_files_to_appropriate_folders(thumbnail_path);
      end
    end
  end


  #
  # This method is used to process and parse the
  # for media content from the dynamic content
  #
  def process_parse_dynamic_content(links_to_migrate)
    links_to_migrate.each do |link|
      link = link.gsub("\n", '');
      response_from_content_url = Contenthelper.get_content_from_url(link);
      if (response_from_content_url)
        if response.search('div#mainContent').nil?
          content_to_migrate = response.search('body');
        else
          content_to_migrate = response.search('div#mainContent');
        end
        Contenthelper.copy_content_media_references(content_to_migrate.to_s);
      end
    end
  end

  #
  # This method parses the content by reading each file from
  # database
  #
  def parse_content(content)
    begin
      while row = content.fetch do
        db_file_path = Contenthelper.purify_file_path(row[1]);
        destination_file_name = row[2];
        complete_source_path = Immutable.config.content_source_path + db_file_path + destination_file_name;
        status = File.file?(complete_source_path);
        case status
          when true
            source_file_handler = File.open(complete_source_path)
            data_to_process = source_file_handler.read();
            self.parse_hrefs_media(data_to_process);
            self.parse_content_for_images(data_to_process);
          when false
            Immutable.log.warn " - Source WebPage ID #{row['web_page_id']} does not exists at #{complete_source_path} "
        end
      end
    end
  end

  #
  # This method parses each file for a tags
  # and calls the copy function to copy them
  #
  def parse_hrefs_media(data_to_migrate)
    doc_to_migrate = Nokogiri::HTML(data_to_migrate);
    doc_to_migrate.css('a').each do |a|
      src = a.attribute('href').to_s;
      src.gsub('http://www.crossroads.net/', '/');
      if (src['http://'])
        Immutable.log.info " - > #{ src } we do not need this file   ";
      else
        self.copy_files_to_appropriate_folders(src)
      end
    end
  end

  #
  # This method parses each file for image tags media
  # and calls the copy function to copy them
  #
  def parse_content_for_images(data_to_migrate)
    doc_to_migrate = Nokogiri::HTML(data_to_migrate);
    doc_to_migrate.css('img').each do |img|
      src = img.attribute('href').to_s;
      src.gsub('http://www.crossroads.net/', '/');
      if (src['http://'])
        Immutable.log.info " - > #{ src } we do not need this file   ";
      else
        self.copy_files_to_appropriate_folders(src)
      end
    end
  end

  #
  # This method  copies required files to
  # appropriate folders which will be moved to S3
  #
  def copy_files_to_appropriate_folders(file)
    file_to_copy = Immutable.config.legacy_htdocs_path + file
    status = File.file?(file_to_copy);
    case status
      when true
        if file_to_copy['.pdf']
          FileUtils.cp(file_to_copy, 'pdf/');
        elsif file_to_copy['.jpg']
          FileUtils.cp(file_to_copy, 'jpg/');
        elsif file_to_copy['.jpeg']
          FileUtils.cp(file_to_copy, 'jpeg/');
        elsif file_to_copy['.png']
          FileUtils.cp(file_to_copy, 'png/');
        elsif file_to_copy['.gif']
          FileUtils.cp(file_to_copy, 'gif/');
        elsif file_to_copy['.mp3']
          FileUtils.cp(file_to_copy, 'mp3/');
        elsif file_to_copy['.mp4']
          FileUtils.cp(file_to_copy, 'mp4/');
        elsif file_to_copy['.doc']
          FileUtils.cp(file_to_copy, 'doc/');
        elsif file_to_copy['.flv']
          FileUtils.cp(file_to_copy, 'flv/');
        else
          FileUtils.cp(file_to_copy, 'all/');
        end
      when false
        Immutable.log.info " - > #{ file_to_copy } does not exists  ";
    end
  end

end
