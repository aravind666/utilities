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
  #
  def copy_media
    begin
      self.setup_folders_required;
      self.copy_content_media_references;
      self.copy_dynamic_content_media_references;
      self.copy_message_media_references;
      self.copy_audio_post_media_references;
      self.copy_video_post_media_references;
      self.copy_blog_post_media_references;
      self.process_series_media_reference;
    end
  end

  #
  # This method creates required directory
  # It also clears the directories to freshly migrate things
  #
  # * Create directories for the mentioned list
  # * doc, png, jpg, jpeg, gif, pdf, mp3, flv, mp4, all
  # * and removes the mentioned sub files/directories
  #
  # copy.setup_folders_required
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

  def copy_blog_post_media_references
    blog_data = Contenthelper.get_all_blog_posts();
    self.process_blog_data_for_media(blog_data);

    puts "Completed copying blog post media elements";
  end

  #
  # This method copies all message media references to
  # it appropriate folders
  #
  # * get all the media content related to message and process them
  #
  # copy.copy_message_media_references
  #
  def copy_message_media_references
    message_media_data = Mediahelper.get_all_media_from_all_messages();
    self.process_media_data(message_media_data);
    puts "Completed copying message post media elements";
  end

  #
  # This method copies all audio posts media references to
  # it appropriate folders
  #
  # * get all the media references relate to audio and process them
  #
  # copy.copy_audio_post_media_references
  #
  def copy_audio_post_media_references
    audio_data = Mediahelper.get_audio_content();
    self.process_media_data(audio_data);
    puts "Completed copying audio post media elements";
  end

  #
  # This method copies all video posts media references to
  # it appropriate folders
  #
  # * get all the media references relate to video and process them
  #
  # copy.copy_video_post_media_references
  #
  def copy_video_post_media_references
    video_data = Mediahelper.get_media_content();
    self.process_media_data(video_data);
    puts "Completed copying video post media elements";
  end

  #
  # This method copies all dynamic content  posts media references to
  # it appropriate folders
  #
  # * get all the media references relate to links and process them
  #
  # copy.copy_dynamic_content_media_references
  #
  def copy_dynamic_content_media_references
    links_to_migrate = Contenthelper.get_dynamic_links_to_migrate();
    self.process_parse_dynamic_content(links_to_migrate);
    puts "Completed copying dynamic content media elements";
  end


  #
  # This method copies all content media references to
  # it appropriate folders
  #
  # * get all the media references relate to content and process them
  #
  # copy.copy_content_media_references
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
  # * get the media path and replace the domain with /
  # * copies them to the related folder
  # * check for all the possible paths in the legacy htdocs path
  # * append the existing thumbnail image to the path to process
  #
  # copy.process_media_data(array)
  #
  def process_media_data(message_media_data)
    message_media_data.each do |media|
      lqpath = media['LowQFilePath'];

      if !lqpath['s3.amazonaws.com'] && !lqpath['video.crossroads.net']
        file = media['LowQFilePath'] + media['HighQFilePath'];
        file.gsub('http://www.crossroads.net/', '/');
        file.gsub('https://www.crossroads.net/', '/');
        self.copy_files_to_appropriate_folders(file);
      end

      status = false
      thumbnail = media['ThumbImagePath'].to_s;

      if !thumbnail.empty?
        if (File.file?(Immutable.config.legacy_htdocs_path+"/players/media/smallThumbs/" + thumbnail))
          status = true;
          thumbnail_path =  "/players/media/smallThumbs/" + thumbnail;
        elsif (File.file?(Immutable.config.legacy_htdocs_path + "/players/media/mediumHz/" + thumbnail))
          status = true;
          thumbnail_path = "/players/media/mediumHz/" + thumbnail;
        elsif (File.file?(Immutable.config.legacy_htdocs_path+"/uploadedfiles/" + thumbnail))
          status = true;
          thumbnail_path =  "/uploadedfiles/" + thumbnail;
        elsif (File.file?(Immutable.config.legacy_htdocs_path+"/images/uploadedImages/" + thumbnail))
          status = true;
          thumbnail_path =  "/images/uploadedImages/" + thumbnail;
        end
        if status
          self.copy_files_to_appropriate_folders(thumbnail_path);
        end
      end
    end
  end

  #
  # This method processes blog data to get all
  # media data required to move to s3
  #
  # * get all audio files related to blog post
  # * get all image files related to blog post
  # * get all inline media files related to blog post
  #
  # copy.process_blog_data_for_media(array)
  #
  def process_blog_data_for_media(blog_data)
    if blog_data.fetchable? then
      blog_data.each do |data|
        content = '';
        blog_media_list = Mediahelper.media_for_blog_post(data['postId']);
        if blog_media_list.fetchable? then
          blog_media_list.each do |media|
            case media[10] # checking for content type
              when 5, 11 # type audio
                table = 'audio';
                audio_list = Mediahelper.get_all_media_for_blog(data['postId'], table);
                self.process_media_for_blog_post(audio_list,table)
              when 10 # type image
                table = 'image';
                image_list = Mediahelper.get_all_media_for_blog(data['postId'], table);
                self.process_media_for_blog_post(image_list,table)
            end
          end
        end
        content_to_migrate = Contenthelper.get_blog_content_matter(data);
        self.parse_hrefs_media(content_to_migrate);
        self.parse_content_for_images(content_to_migrate);
      end
    else
      Immutable.log.info "No blog post available";
    end
  end

  #
  # This method is used to copy all blog media files
  # required to move to s3
  #
  # * copy all audio files related to blog post
  # * copy all video files related to blog post
  # * copy all image files related to blog post
  #
  # copy.process_media_for_blog_post(media_list,table)
  #
  def process_media_for_blog_post(media_list,table)
    if media_list.fetchable? then
      media_list.each do |media|
        case table
          when 'video'
            still_image_path = media['playerUrl'] + media['stillImage'];
            still_image_path = still_image_path.to_s;
            self.copy_files_to_appropriate_folders(still_image_path);
          when 'audio'
            if (media['path'].nil? && media['hosturl'].nil?)
              url = '';
            else
              url = media['hostUrl'] + media['path'];
            end
            media_path = url.to_s;
            self.copy_files_to_appropriate_folders(media_path);
          when 'image'
            poster_path = media['imageUrl'] + media['path'];
            poster_path = poster_path.to_s;
            self.copy_files_to_appropriate_folders(poster_path);
        end
      end
    end
  end

  #
  # This method is used to process and parse the
  # for media content from the dynamic content
  #
  # * for each link check in the div with if main content
  # * if the above data is missing then check in the body
  # * and parse the hrefs and the images from anchor tag and img src respectively
  #
  # copy.process_parse_dynamic_content('string link')
  #
  def process_parse_dynamic_content(links_to_migrate)
    links_to_migrate.each do |link|
      link = link.gsub("\n", '');
      response_from_content_url = Contenthelper.get_content_from_url(link);
      if (response_from_content_url)
        if response_from_content_url.search('div#mainContent').nil?
          content_to_migrate = response_from_content_url.search('body');
        else
          content_to_migrate = response_from_content_url.search('div#mainContent');
        end
        self.parse_hrefs_media(content_to_migrate);
        self.parse_content_for_images(content_to_migrate);
      end
    end
  end

  #
  # This method parses the content by reading each file from
  # database
  #
  # * purify the file path
  # * get the source path and read
  # * and parse the hrefs and the images from anchor tag and img src respectively
  #
  # copy.parse_content(array)
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
  # * for each anchor tag get the href associated to it
  # * replace the domain with /
  # * and process it to appropriate folders
  #
  # copy.parse_hrefs_media(string)
  #
  def parse_hrefs_media(data_to_migrate)
    doc_to_migrate = Nokogiri::HTML(data_to_migrate.to_s);
    doc_to_migrate.css('a').each do |a|
      src = a.attribute('href').to_s;
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
  # * for each img tag get the src associated to it
  # * replace the domain with /
  # * and process it to appropriate folders
  #
  # copy.parse_content_for_images(string)
  #
  def parse_content_for_images(data_to_migrate)
    doc_to_migrate = Nokogiri::HTML(data_to_migrate.to_s);
    doc_to_migrate.css('img').each do |img|
      src = img.attribute('src').to_s;
      if (src['http://'])
        Immutable.log.info " - > #{ src } we do not need this file   ";
      else
        self.copy_files_to_appropriate_folders(src)
      end
    end
  end

  def process_series_media_reference
    begin
      series_data = Mediahelper.get_all_series
      self.copy_series_media_references(series_data)
    end
  end

  #
  # This method is used to copy series image files
  # required to move to s3
  #
  # * copy all image files related to series content
  #
  # copy.copy_series_media_references(series_data)
  #
  def copy_series_media_references(series_data)
      status = false
      series_image_path = ''
      if series_data.fetchable? then
        series_data.each do |series|
          series_image_file = series['ImageFile'].to_s
          series_image_file1 = series['ImageFile1'].to_s
          series_image_file.gsub!('../../../', '')
          series_image_file1.gsub!('../../../', '')
          if series_image_file1=='' || series_image_file1.nil?
            series_image = "/players/media/series/#{series_image_file}"
          else
            series_image = "/players/media/series/#{series_image_file1}"
          end

          if series_image['img/graphics/']
            series_image = series_image.gsub('/players/media/series/', '')
          end

          if !series_image.empty?
            if File.file?("#{Immutable.config.legacy_htdocs_path}#{series_image}" )
              status = true;
              series_image_path = series_image
            end
          end
          if status
            self.copy_files_to_appropriate_folders(series_image_path);
          end
        end
      end
      abort('Successfully migrated series images')
  end

  #
  # This method  copies required files to
  # appropriate folders which will be moved to S3
  #
  # * for each file
  # * check the following extensions to copy to the folder
  # * such as pdf, jpg, jpeg, png, gif, mp3, mp4, doc, flv and all
  # * and process it to appropriate folders
  #
  # copy.copy_files_to_appropriate_folders(file)
  #
  def copy_files_to_appropriate_folders(file)

    file = file.gsub('http://www.crossroads.net/', '/');
    file = file.gsub('https://www.crossroads.net/', '/');
    file = file.gsub('../../', '/');
    file = file.gsub('../', '/');
    file = file.gsub('%20', ' ');
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
