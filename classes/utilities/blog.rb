# encoding: ASCII-8BIT

# Blog class defines the migration logic and uses the related helper
# class for fetching the blog data which flags the migrated content to yes
#
# Author::    Sandeep A R  (mailto:sandeep.setty@costrategix.com)
# Copyright:: Copyright (c) 2014 Crossroads
# License::   MIT
#
# Initiating this class leads to migration of blog
#
class Blog

  #
  # Initialize the blog content migration process
  #
  def initialize
    File.delete('missing_email_address.log') if File.exist?('missing_email_address.log');
    File.delete('blog_posts_does_not_exists.log') if File.exist?('blog_posts_does_not_exists.log');
    File.delete('blog_posts_missing.log') if File.exist?('blog_posts_missing.log');
    self.migrate_blog();
  end

  # Public:
  # function to get the blog post which are ready to migrate
  #
  # Public: migrate blog content
  #
  # Gets all blog post from DB
  # to generate blog content jekyll front matter
  #
  def migrate_blog
    blog_data = BlogHelper.get_all_blog_posts();
    self.process_blog_data(blog_data);
  end

  #
  # Public: generates jekyll front matter for each blog post
  #
  # *blog_data* - Array of blog post records
  #
  # Returns success message
  #
  def process_blog_data(blog_data)
    if blog_data.fetchable? then
      blog_data.each do |data|
        content = '';
        blog_media_list = Mediahelper.media_for_blog_post(data['postId']);
        media_front_matter = self.process_blog_media_list(data['postId'], blog_media_list);
        if media_front_matter != 'FLV'
          front_matter = self.get_jekyll_front_matter_blog_post(data, media_front_matter);
          content = BlogHelper.get_blog_content_matter(data);
          content = ContentHelper.update_html_with_new_image_paths(content.to_s);
          content = ContentHelper.update_html_with_new_media_hrefs(content.to_s);
          content = BlogHelper.update_html_with_milacron_href_in_content_posts(content.to_s);
          content = BlogHelper.remove_unwanted_paragraph(content.to_s)
          content = content.encode('utf-8', 'binary', :invalid => :replace,:undef => :replace, :replace => '')
          file_write_data = front_matter.force_encoding('UTF-8') + content.force_encoding('UTF-8');
          self.migrate_by_adding_jekyll_front_matter(file_write_data, data);
        else
          self.log_flv_videos(data, media_front_matter);
        end
      end

    else
      Immutable.log.info "No blog post available";
    end
    abort('Successfully migrated blog posts in the specified destination');
  end

  #
  # This method processes blog data to get all
  # media data related to blog
  #
  # * get all audio files related to blog post
  # * get all image files related to blog post
  # * get all inline media files related to blog post
  #
  # Blog.process_blog_media_list(id, media_data)
  #
  def process_blog_media_list(id, media_data)
    media_front_matter = '';
    if media_data.fetchable? then
      media_data.each do |media|
        case media[10] # checking for content type
          when 1, 4, 9 # type video
            table = 'video';
            video_list = Mediahelper.get_all_media_for_blog(id, table);
            media_front_matter = self.get_media_front_matter_data(video_list, table);
          when 5, 11 # type audio
            table = 'audio';
            audio_list = Mediahelper.get_all_media_for_blog(id, table);
            media_front_matter = self.get_media_front_matter_data(audio_list, table);
          when 10 # type image
            table = 'image';
            image_list = Mediahelper.get_all_media_for_blog(id, table);
            media_front_matter = self.get_media_front_matter_data(image_list, table);
        end
      end
    end
    return media_front_matter;
  end

  #
  # This method processes blog media data to get all
  # blog media content front matter
  #
  # Blog.get_media_front_matter_data(media_list, table)
  #
  # Returns blog media content front matter
  #
  def get_media_front_matter_data(media_list, table)
    front_matter = '';
    if media_list.fetchable? then
      media_list.each do |list|
        case table
          when 'video'
            image = list['playerUrl'] + list['stillImage'];
            image = ContentHelper.replace_image_sources_with_new_paths(image)
            if (list['hiDownload'].nil?)
              front_matter = 'FLV';
            else
              uri = URI.parse(list['hiDownload'])
              video_filename = File.basename(uri.path)
              video_file_path = "#{Immutable.config.s3url}/other-media/video/#{video_filename}"
              front_matter = "\nvideo: \"#{video_file_path}\"";
              front_matter += "\nvideo-width: #{list['hiWidth']}";
              front_matter += "\nvideo-height: #{list['hiHeight']}";
              front_matter += "\nvideo-image: #{image}";
            end
          when 'audio'
            path = list['path'];
            host_url = list['hostUrl'];
            if (path.nil? && host_url.nil?)
              url = '';
            elsif path['s3.amazonaws']
              url = path
            else
              url = "#{host_url}#{path}";
            end
            uri = URI.parse(url)
            audio_filename = File.basename(uri.path)
            audio_file_path = "#{Immutable.config.s3url}/other-media/audio/#{audio_filename}"
            front_matter = "\naudio: \"#{audio_file_path}\"";
          when 'image'
            poster = list['imageUrl'] + list['path'];
            poster = ContentHelper.replace_image_sources_with_new_paths(poster);
            front_matter = "\nimage: \"#{poster}\"";
            if (list['width'] == 0)
              list['width'] = '';
            end
            front_matter += "\nimage-width: #{list['width']}";
            front_matter += "\nimage-height: #{list['height']}";
          else
            front_matter = '';
        end
      end
    end
    return front_matter;
  end

  #
  # This method generates the actual and complete front matter for
  # blog content
  #
  # Blog.get_jekyll_front_matter_blog_post(data, mediaElements)
  #
  # Returns blog post jekyll front matter
  #
  def get_jekyll_front_matter_blog_post(data, mediaElements)
    mainTitle = data['title'].gsub /"/, '';
    tagCategory = ContentHelper.purify_title_by_removing_special_characters(data['name'].downcase.strip);
    front_matter = "---\nlayout: post\ntitle: \"#{mainTitle}\"";
    front_matter += "\nsubtitle: \"#{data['subtitle']}\"";
    front_matter += "\ndate: #{data['createdDate'].strftime('%Y-%m-%d')}";
    front_matter += "\ncategory: \"#{data['name']}\"";
    front_matter += "\ntag: \n - #{tagCategory}";
    front_matter += "\ncomments: true";
    front_matter += "\ncreated-by: \"#{data['FirstName']}\"";
    front_matter += mediaElements;
    front_matter += "\n---";
    front_matter += "\n\n";
    return front_matter;
  end

  #
  # creates a jekyll front matter page for blog post
  #
  # adds the jekyll front matter and the content to a file
  # and moves to the destination path
  #
  # Blog.migrate_by_adding_jekyll_front_matter(html_data, blog_data)
  #
  # Return file by writing the blog post front matter to the given destination path
  #
  def migrate_by_adding_jekyll_front_matter(html_data, blog_data)
    begin
      target_file_path = "#{Immutable.config.blog_destination_path}/";
      title = ContentHelper.purify_title_by_removing_special_characters(blog_data['title'].downcase.strip);

      target_file_path += "#{blog_data['createdDate'].strftime('%Y-%m-%d')}-#{blog_data['id']}-#{title}.html"
      migrated_blog_file_handler = File.open(target_file_path, 'w');
      migrated_blog_file_handler.write(html_data);
    end
  end

  #
  # used to log the non mp4 type files
  #
  # Blog.log_flv_videos(data, front_matter)
  #
  # Return non mp4 log information
  #
  def log_flv_videos(data, front_matter)
    begin
      Immutable.log.info "Post-id: #{data['postId']}";
      Immutable.log.info "Title: #{data['title']}";
      Immutable.log.info "Tag: #{data['name']}";
      Immutable.log.info "Front-Matter: #{front_matter}";
      Immutable.log.info '-------------------------';
    end
  end
end
