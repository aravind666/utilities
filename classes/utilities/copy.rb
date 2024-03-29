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
=begin
      self.setup_folders_required;
      self.copy_content_media_references;
      self.copy_dynamic_content_media_references;
      self.upload_content_media_reference_to_s3

      self.setup_folders_required;
      self.process_series_media_reference;
      self.upload_content_media_reference_to_s3;

      self.setup_folders_required;
      self.copy_audio_post_media_references;
      self.copy_video_post_media_references;
      self.upload_AV_media_reference_to_s3;

      self.setup_folders_required;
      self.copy_blog_post_media_references;
      self.upload_content_media_reference_to_s3;
      self.setup_folders_required;

      self.copy_message_media_references;
      self.upload_message_media_reference_to_s3;
      self.setup_folders_required;
=end
      self.organize_existing_s3_files;
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
    blog_data = BlogHelper.get_all_blog_posts();
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
    links_to_migrate = ContentHelper.get_dynamic_links_to_migrate();
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
    content_data = ContentHelper.get_content_from_database();
    self.parse_content(content_data);
    puts "Completed copying content media";
  end

  #
  # This method organizes s3
  #
  # * organize s3 bucket path as mentioned in MIL-257
  #
  #
  def organize_existing_s3_files
    self.organize_message_media_references_in_s3;
    self.organize_other_AV_references_with_in_s3;
  end

  #
  # This method organizes existing messages with in S3
  #
  # * organize s3 bucket path for message media as mentioned in MIL-257
  #
  #
  def organize_message_media_references_in_s3
    message_media_data = Mediahelper.get_all_media_from_all_messages();
    message_media_data.each do |media|
      self.organize_message_media_within_s3(media);
    end
  end

  #
  # This method organizes existing videos and audios which dont belong to messages with in S3
  #
  # * organize s3 bucket path for other audio and video as mentioned in MIL-257
  #
  #
  def organize_other_AV_references_with_in_s3
    video_list_in_s3 = Mediahelper.get_media_content();
    video_list_in_s3.each do |video|
      if(video['iPodVideo'].length > 0)
        url = video['iPodVideo'];
        url = url.gsub('https://s3.amazonaws.com/crossroadsvideomessages/','');
        video_filename = url.gsub('http://s3.amazonaws.com/crossroadsvideomessages/','');
        if(video_filename.length > 0)
          self.organize_s3_video_posts(URI.unescape(video_filename));
        end
      end
    end
    audio_list_in_s3 = Mediahelper.get_audio_content();
    audio_list_in_s3.each do |audio|
      self.organize_s3_audio_posts(audio['HighQFilePath']);
    end
    puts " Completed Organizing other Videos and Audios "
  end


  #
  # This method organizes existing messages with in S3
  #
  # * organize files in S3 based on file type
  #
  #
  def organize_message_media_within_s3(media)
    if media['ContentTypeID'] == 5
      self.organize_s3_audio_message(media['HighQFilePath']);
    elsif ( media['ContentTypeID'] == 4 )
        url = media['iPodVideo'];
        url = url.gsub('https://s3.amazonaws.com/crossroadsvideomessages/','');
        video_filename = url.gsub('http://s3.amazonaws.com/crossroadsvideomessages/','');
        if(video_filename.length > 0)
          self.organize_s3_video_message(URI.unescape(video_filename));
        end

    end
  end

  #
  # This method organizes s3 video message path
  #
  # * organize s3 bucket path for message videos as mentioned in MIL-257
  #
  #
  def organize_s3_audio_message(file)
    s3 = Immutable.getS3;
    destination_bucket = s3.buckets['crossroads-media'].objects;
    audio_file_to_organize = s3.buckets['crossroadsaudiomessages'].objects[file];
    if (s3.buckets['crossroadsaudiomessages'].objects[file].exists?)
      puts " Copying the #{file} in to messages/audio/";
      new_audio_message_bucket_path = "messages/audio/#{file}"
      destination = destination_bucket[new_audio_message_bucket_path]
      audio_file_to_organize.copy_to(destination, { :acl => :public_read })
    end
  end


  #
  # This method organizes s3 video message path
  #
  # * organize s3 bucket path for message videos as mentioned in MIL-257
  #
  #
  def organize_s3_video_message(file)
    s3 = Immutable.getS3;
    destination_bucket = s3.buckets['crossroads-media'].objects;
    video_file_to_organize = s3.buckets['crossroadsvideomessages'].objects[file];
    if (s3.buckets['crossroadsvideomessages'].objects[file].exists?)
      puts " Copying the #{file} in to messages/video/";
      new_video_message_bucket_path = "messages/video/#{file}"
      destination = destination_bucket[new_video_message_bucket_path]
      video_file_to_organize.copy_to(destination, { :acl => :public_read })
    end
  end

  #
  # This method organizes s3 video message path
  #
  # * organize s3 bucket path for message videos as mentioned in MIL-257
  #
  #
  def organize_s3_video_posts(file)
    s3 = Immutable.getS3;
    destination_bucket = s3.buckets['crossroads-media'].objects;
    video_file_to_organize = s3.buckets['crossroadsvideomessages'].objects[file];
    if (s3.buckets['crossroadsvideomessages'].objects[file].exists?)
      puts " Copying the #{file} in to other-media/video/";
      new_video_message_bucket_path = "other-media/video/#{file}"
      destination = destination_bucket[new_video_message_bucket_path]
      video_file_to_organize.copy_to(destination, { :acl => :public_read })
    end
  end

  #
  # This method organizes s3 video message path
  #
  # * organize s3 bucket path for message videos as mentioned in MIL-257
  #
  #
  def organize_s3_audio_posts(file)
    s3 = Immutable.getS3;
    destination_bucket = s3.buckets['crossroads-media'].objects;
    audio_file_to_organize = s3.buckets['crossroadsaudiomessages'].objects[file];
    if (s3.buckets['crossroadsaudiomessages'].objects[file].exists?)
      puts " Copying the #{file} in to other-media/audio/";
      new_audio_message_bucket_path = "other-media/audio/#{file}"
      destination = destination_bucket[new_audio_message_bucket_path]
      audio_file_to_organize.copy_to(destination, { :acl => :public_read })
    end
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
          thumbnail_path = "/players/media/smallThumbs/" + thumbnail;
        elsif (File.file?(Immutable.config.legacy_htdocs_path + "/players/media/mediumHz/" + thumbnail))
          status = true;
          thumbnail_path = "/players/media/mediumHz/" + thumbnail;
        elsif (File.file?(Immutable.config.legacy_htdocs_path+"/uploadedfiles/" + thumbnail))
          status = true;
          thumbnail_path = "/uploadedfiles/" + thumbnail;
        elsif (File.file?(Immutable.config.legacy_htdocs_path+"/uploadedfiles/1/" + thumbnail))
          status = true;
          thumbnail_path = "/uploadedfiles/1/" + thumbnail;
        elsif (File.file?(Immutable.config.legacy_htdocs_path+"/images/uploadedImages/" + thumbnail))
          status = true;
          thumbnail_path = "/images/uploadedImages/" + thumbnail;
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
              when 1, 4, 9 # type video
                table = 'video';
                video_list = Mediahelper.get_all_media_for_blog(data['postId'], table);
                self.process_media_for_blog_post(video_list, table)
              when 5, 11 # type audio
                table = 'audio';
                audio_list = Mediahelper.get_all_media_for_blog(data['postId'], table);
                self.process_media_for_blog_post(audio_list, table)
              when 10 # type image
                table = 'image';
                image_list = Mediahelper.get_all_media_for_blog(data['postId'], table);
                self.process_media_for_blog_post(image_list, table)
            end
          end
        end
        content_to_migrate = BlogHelper.get_blog_content_matter(data);
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
  def process_media_for_blog_post(media_list, table)
    if media_list.fetchable? then
      media_list.each do |media|
        case table
          when 'video'
            still_image_path = media['playerUrl'] + media['stillImage'];
            still_image_path = still_image_path.to_s;
            self.copy_files_to_appropriate_folders(still_image_path);
            video_url = media['hiDownload'];
            video_url = video_url.to_s;
            if (video_url['s3.amazonaws.com'])
              uri = URI.parse(media['hiDownload'])
              video_filename = File.basename(uri.path)
              self.organize_s3_video_posts(video_filename);
            end
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
      response_from_content_url = ContentHelper.get_content_from_url(link);
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
        db_file_path = ContentHelper.purify_file_path(row[1]);
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
    series_image = ''
    if series_data.fetchable? then
      series_data.each do |series|
        series_image_file = series['ImageFile'].to_s
        series_image_file1 = series['ImageFile1'].to_s
        series_image_file2 = series['ImageFile2'].to_s
        series_image_file.gsub!('../../../', '')
        series_image_file1.gsub!('../../../', '')

        if series_image_file2 != ''
          series_image = series_image_file2
        elsif series_image_file1 != ''
          series_image = series_image_file1
        elsif series_image_file != ''
          series_image = series_image_file
        end
        series_image = "/players/media/series/#{series_image}"
        if series_image['img/graphics/']
          series_image = series_image.gsub('/players/media/series/', '')
        end

        if !series_image.empty?
          if File.file?("#{Immutable.config.legacy_htdocs_path}#{series_image}")
            status = true;
            series_image_path = series_image
          end
        end
        if status
          self.copy_files_to_appropriate_folders(series_image_path);
        end
      end
    end
    puts('Successfully migrated series images')
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


  #
  # This method organizes s3
  #
  # * upload content media references to s3
  #
  #
  def upload_content_media_reference_to_s3
    cmd_jpg = "aws s3 cp jpg/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_jepg = "aws s3 cp jpeg/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_png = "aws s3 cp png/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_gif = "aws s3 cp gif/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_docs = "aws s3 cp doc/ s3://crossroads-media/documents/ --recursive --acl public-read"
    cmd_pdf = "aws s3 cp pdf/ s3://crossroads-media/documents/ --recursive --acl public-read"
    cmd_mp3 = "aws s3 cp mp3/ s3://crossroads-media/other-media/audio/ --recursive --acl public-read"
    cmd_mp4 = "aws s3 cp mp4/ s3://crossroads-media/other-media/video/ --recursive --acl public-read"
    system(cmd_jpg);
    system(cmd_jepg);
    system(cmd_png);
    system(cmd_gif);
    system(cmd_docs);
    system(cmd_pdf);
    system(cmd_mp3);
    system(cmd_mp4);
    puts " Completed uploading media references to S3 "
  end

  #
  # This method organizes s3
  #
  # * upload message media references to s3
  #
  #
  def upload_message_media_reference_to_s3
    cmd_jpg = "aws s3 cp jpg/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_jepg = "aws s3 cp jpeg/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_png = "aws s3 cp png/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_gif = "aws s3 cp gif/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_docs = "aws s3 cp doc/ s3://crossroads-media/documents/ --recursive --acl public-read"
    cmd_pdf = "aws s3 cp pdf/ s3://crossroads-media/documents/ --recursive --acl public-read"
    cmd_mp3 = "aws s3 cp mp3/ s3://crossroads-media/messages/audio/ --recursive --acl public-read"
    cmd_mp4 = "aws s3 cp mp4/ s3://crossroads-media/messages/video/ --recursive --acl public-read"
    system(cmd_jpg);
    system(cmd_jepg);
    system(cmd_png);
    system(cmd_gif);
    system(cmd_docs);
    system(cmd_pdf);
    system(cmd_mp3);
    system(cmd_mp4);
    puts " Completed uploading message references to S3 "
  end


  #
  # This method uploads other audio and video along with images to s3
  #
  # * upload audio media references to s3
  #
  #
  def upload_AV_media_reference_to_s3
    cmd_jpg = "aws s3 cp jpg/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_jepg = "aws s3 cp jpeg/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_png = "aws s3 cp png/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_gif = "aws s3 cp gif/ s3://crossroads-media/images/ --recursive --acl public-read"
    cmd_docs = "aws s3 cp doc/ s3://crossroads-media/documents/ --recursive --acl public-read"
    cmd_pdf = "aws s3 cp pdf/ s3://crossroads-media/documents/ --recursive --acl public-read"
    cmd_mp3 = "aws s3 cp mp3/ s3://crossroads-media/music/audio/ --recursive --acl public-read"
    cmd_mp4 = "aws s3 cp mp4/ s3://crossroads-media/other-media/video/ --recursive --acl public-read"
    system(cmd_jpg);
    system(cmd_jepg);
    system(cmd_png);
    system(cmd_gif);
    system(cmd_docs);
    system(cmd_pdf);
    system(cmd_mp3);
    system(cmd_mp4);
    puts " Completed uploading AV references to S3 "
  end

end