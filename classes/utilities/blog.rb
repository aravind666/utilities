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
    # Create Blog object by initializing the migration flow
    #
    def initialize
        self.migrate_blog();
    end

    #
    # function to get the blog post which are ready to migrate
    #
    def migrate_blog
        blog_data = Mediahelper.get_all_blog_posts();
        self.process_blog_data(blog_data);
    end

    #
    # Process the received data into a jekyll format
    #
    def process_blog_data(blog_data)
        if blog_data.fetchable? then
            blog_data.each do |data|
                content = '';
                getMediaElements = self.media_for_blog_post(data['postId']);
                if (getMediaElements == 'FLV')
                    self.log_flv_videos(data);
                else
                    front_matter = self.get_jekyll_front_matter_blog_post(data, getMediaElements);
                    content = self.get_jekyll_content_matter(data);
                    file_write_data = front_matter + content;
                    self.migrate_by_adding_jekyll_front_matter(file_write_data, data);
                end
            end
        else
            Immutable.log.info "No blog post available";
        end
        abort('Successfully migrated blog posts in the specified destination');
    end

    #
    # get all the media elements of a blog post
    #
    def media_for_blog_post(id)
      media_data = Mediahelper.get_media_content_by_media_content_id(id);#this to know the type of media used in a blog
      media_front_matter = '';
      if media_data.fetchable? then
          media_data.each do |media|
            case media[10] # checking for content type
              when 1, 4, 9  # type video
                  table = 'video';
                  media_list = Mediahelper.get_all_media_for_blog(id, table);
                  media_front_matter = self.get_media_front_matter_data(media_list, table);
              when 5, 11 # type audio
                  table = 'audio';
                  media_list = Mediahelper.get_all_media_for_blog(id, table);
                  media_front_matter = self.get_media_front_matter_data(media_list, table);
              when 10 # type image
                  table = 'image';
                  media_list = Mediahelper.get_all_media_for_blog(id, table);
                  media_front_matter = self.get_media_front_matter_data(media_list, table);
              else
                  media_front_matter = '';
            end
          end
      end
      return media_front_matter;
    end

    #
    # function get the media related front matter based on its type
    #
    def get_media_front_matter_data(media_list, table)
        front_matter = '';
        if media_list.fetchable? then
          media_list.each do |list|
            case table
              when 'video'
                image = list['playerUrl'] + list['stillImage'];
                front_matter = "\nvideo: \"#{list['hiDownload']}\"";
                front_matter += "\nvideo-width: #{list['hiWidth']}";
                front_matter += "\nvideo-height: #{list['hiHeight']}";
                front_matter += "\nvideo-image: #{image}";
                if (list['hiDownload'].nil?)
                  front_matter = 'FLV';
                  return front_matter;
                end
              when 'audio'
                if (list['path'].nil? && list['hosturl'].nil?)
                  url = '';
                else
                  url = list['hostUrl'] + list['path'];
                end
                front_matter = "\naudio: \"#{url}\"";
              when 'image'
                poster = list['imageUrl'] + list['path'];
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
    # Function which returns the actual and complete front matter
    #
    def get_jekyll_front_matter_blog_post(data, mediaElements)
        mainTitle = data['title'].gsub /"/, '';
        tagCategory = Contenthelper.purify_title_by_removing_special_characters(data['name'].downcase.strip);
        front_matter = "---\nlayout: post\ntitle: \"#{mainTitle}\"";
        front_matter += "\nsubtitle: \"#{data['subtitle']}\"";
        front_matter += "\ndate: #{data["createdDate"].strftime("%Y-%m-%d %H:%M:%S")}";
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
    # Gets the actual blog content
    #
    def get_jekyll_content_matter(data)
        para1 = data['paragraph1'];
        para2 = data['paragraph2'];

        if (para1.nil?)
            content = para2;
        elsif (para2.nil?)
            content = para1;
        else
            content = '';
        end

        if (!para2.nil? && !para1.nil?)
            content = para1 + para2;
        end
        mainContent = Contenthelper.purify_by_removing_special_characters(content);
        return mainContent;
    end

    #
    # adds the jekyll front matter and the content to a file and moves to the destination path
    #
    def migrate_by_adding_jekyll_front_matter(html_data, blog_data)
        begin
            target_file_path = "#{Immutable.config.blog_destination_path}/";
            title = Contenthelper.purify_title_by_removing_special_characters(blog_data["title"].downcase.strip);
            target_file_path += "#{blog_data["createdDate"].strftime("%Y-%m-%d-%H-%M-%S")}-#{title}.html"
            migrated_blog_file_handler = File.open(target_file_path, 'w');
            migrated_blog_file_handler.write(html_data);
        end
    end

    #
    # method to log the non mp4 type files
    #
    def log_flv_videos(data)
        begin
          Immutable.log.info "Post-id: #{data['postId']}";
          Immutable.log.info "Title: #{data['title']}";
          Immutable.log.info "Tag: #{data['name']}";
          Immutable.log.info "-------------------------";
        end
    end
end