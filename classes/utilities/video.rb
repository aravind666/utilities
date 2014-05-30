# encoding: ASCII-8BIT

# Video class defines the migration logic and uses the related helper 
# class for fetching the data
#
# Author::    Sandeep A R  (mailto:sandeep.setty@costrategix.com)
# Copyright:: Copyright (c) 2014 Crossroads
# License::   MIT
#
# Instiating this class leads to migration of videos
#
class Video

    #
    # Create Video object by initializing the migration flow
    #
    def initialize
        self.migrate_media();
    end

    #
    # Function to migrate the media content
    #
    def migrate_media
        begin
            series_data = Mediahelper.get_all_series();
            self.process_series_data(series_data);
        end
    end

    #
    # Function to process the series data.
    #
    def process_series_data(series_data)
        begin
            series_data.each do |series|
                message_data = Mediahelper.get_all_messages_for_series(series[0]);
                process_message_data(message_data, series);
            end
                abort('Successfully migrated videos in specified destination');
        end
    end

    #
    # This method will process message details by collecting
    # all its media content before migration
    #
    def process_message_data(message_data, series)
        begin
            message_data.each do |message|
            media_content = Mediahelper.get_video_media_content_for_message(message[0]);
              if media_content.fetchable? then
                self.create_video_posts_for_each_video_content(message, series, media_content);
              else
                Immutable.log.info "Message  #{message[0]} does not have any video content";
              end
            end
        end
    end


    #
    # Add media video content front matter
    # this can be used by liquid variables in media layout .
    #
    def create_video_posts_for_each_video_content(message, series, media_content)
        begin
            media_content.each do |media|
                if (media['iPodVideo'].length > 0)
                    front_matter = self.get_jekyll_front_matter_video_post(media,series);
                    self.migrate_by_adding_jekyll_front_matter(front_matter, media);
                end
            end
        end
    end

    #
    # This method returns the frontmatter YAML for the media
    # which is about to get migrated
    #
    def get_jekyll_front_matter_video_post(media,series)
      
      mainTitle = media['Title'].gsub /"/, '';
      video_description = Contenthelper.purify_by_removing_special_characters(media['Description']);
      video_poster = media['ThumbImagePath'];

      front_matter = "---\nlayout: media\ncategory: media\nseries: \"#{series[1]}\"\ntitle: \"#{mainTitle}\"";
      front_matter += "\ndate: #{media["ActiveDate"].strftime("%Y-%m-%d")}";
      front_matter += "\ndescription: \"#{video_description}\""
      front_matter += "\nvideo: \"#{media['iPodVideo']}\"";
      front_matter += "\nvideo-poster: \"#{Immutable.config.image_thumb_base_url}#{video_poster}\"";
      front_matter += "\n---";
      return front_matter;
    end


    #
    # Creates a jekyll page by applying neccessary frontmatter
    #
    def migrate_by_adding_jekyll_front_matter(jekyll_front_matter, media)
        begin
            target_file_path = "#{Immutable.config.video_destination_path}/";
            title = Contenthelper.purify_title_by_removing_special_characters(media["Title"].downcase.strip);
            target_file_path += "#{media["ActiveDate"].strftime("%Y-%m-%d-%H-%M-%S")}-#{title}.md"
            migrated_message_file_handler = File.open(target_file_path, 'w');
            migrated_message_file_handler.write(jekyll_front_matter);
        end
    end

end