# encoding: ASCII-8BIT

# Video class defines the migration logic and uses the related helper 
# class for fetching the data
#
# Author::    Sandeep A R  (mailto:sandeep.setty@costrategix.com)
# Copyright:: Copyright (c) 2014 Crossroads
# License::   MIT
#
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
            media_content = Mediahelper.get_videos_in_media_content_for_message(message[0]);
            if media_content.column_names.size === 0 then
                Immutable.log.info "Message  #{message[0]} does not have any video content";
            else
                front_matter = self.get_jekyll_frontmatter_for_messages(message, series, media_content);
                if (front_matter.length > 0)
                    self.migrate_by_adding_jekyll_front_matter(front_matter, message);
                end
            end
            end
        end
    end

    #
    # Prepare Jekyll Frontmatter for migrated video messages
    #
    #
    def get_jekyll_frontmatter_for_messages(message_data, series, media_content)
        begin
            front_matter = '';
            front_matter = 
                self.add_media_content_front_matter(message_data, series, media_content,front_matter);
            return front_matter
        end
    end

    #
    # Add media video content front matter
    # this can be used by liquid variables in media layout .
    #
    def add_media_content_front_matter(message_data, series, media_content, front_matter)
        begin
            media_content.each do |media|
            case media['ContentTypeID']
            when 4
                # Video -- only IPOD video
                if (media['iPodVideo'].length > 0)
                    mainTitle = message_data[2].gsub /"/, '';
                    front_matter = "---\nlayout: message\ncategory: message\nseries: \"#{series[1]}\"\ntitle: \"#{mainTitle}\"";
                    front_matter += "\ndate: #{message_data["Date"].strftime("%Y-%m-%d")}"

                    video_description = Contenthelper.purify_by_removing_special_characters(media['Description']);
                    video_title = Contenthelper.purify_by_removing_special_characters(media['Title']);
                    video_poster = media['ThumbImagePath'];
                    front_matter += "\ndescription: \"#{video_description}\"\nvideo-title: \"#{video_title}\""
                    front_matter += "\nvideo: \"#{media['iPodVideo']}\"";
                    front_matter += "\nvideo-poster: \"#{Immutable.config.image_thumb_base_url}#{video_poster}\"";

                    front_matter += "\n---";
                end
            else
                    front_matter = '';
            end
            end
        return front_matter;
        end
    end

    #
    # Creates a jekyll page by applying neccessary frontmatter
    #
    def migrate_by_adding_jekyll_front_matter(jekyll_front_matter, message_data)
        begin
            target_file_path = "#{Immutable.config.video_destination_path}/";
            target_file_path += "#{message_data["Title"].downcase.gsub(' ', '_').gsub('/', '-').gsub('?','').gsub('*','').gsub('#','').gsub('@','').gsub('&','_and_')}"
            
            target_file_path += "_#{message_data["Date"].strftime("%Y_%m_%d")}.md";
            target_file_path = target_file_path.gsub '...', '';
            target_file_path = target_file_path.gsub /'/, '';
            # lets remove only quotes in the file name since its non standard
            target_file_path = target_file_path.gsub /"/, '';
            target_file_path = target_file_path.gsub '|', '';
            target_file_path = target_file_path.gsub ':', '';

            migrated_message_file_handler = File.open(target_file_path, 'w');
            migrated_message_file_handler.write(jekyll_front_matter);
        end
    end

end