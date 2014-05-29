# encoding: ASCII-8BIT

# message class which defines various attributes and behaviours which are used in
# message migration
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
#
# Instiating this class leads to migration of messages
#

class Message

  #
  # Create Message object by initilizing the migration flow
  #
  def initialize
    self.migrate_messages();
  end

  #
  # This method actually migrates the content by creating the front matter
  #
  def migrate_messages
    begin
      series_data = Mediahelper.get_all_series();
      self.process_series_data(series_data);
    end
  end

  #
  # This method will process series data by collecting all its respective messages
  #
  def process_series_data(series_data)
    begin
      series_data.each do |series|
        message_data = Mediahelper.get_all_messages_for_series(series[0]);
        process_message_data(message_data, series);
      end
      abort('Successfully migrated messages in specified destination');
    end
  end

  #
  # This method will process message details by collecting
  # all its media content before migration
  #
  def process_message_data(message_data, series)
    begin
      message_data.each do |message|
        media_content = Mediahelper.get_media_content_for_message(message[0]);
        if media_content.column_names.size === 0 then
          Immutable.log.info "Message  #{message[0]} does not have any media content";
        else
          front_matter = self.get_jekyll_frontmatter_for_messages(message, series, media_content);
          self.migrate_by_adding_jekyll_front_matter(front_matter, message);
        end
      end
    end
  end

  #
  # Prepare Jekyll Frontmatter for migrated messages
  #
  #
  def get_jekyll_frontmatter_for_messages(message_data, series, media_content)
    begin
      front_matter = '';
      mainTitle = message_data[2].gsub /"/, '';
      front_matter = "---\nlayout: message\ncategory: message\nseries: \"#{series[1]}\"\ntitle: \"#{mainTitle}\"";
      front_matter += "\ndate: #{message_data["Date"].strftime("%Y-%m-%d")}"
      front_matter = self.add_media_content_front_matter(media_content,front_matter);
      front_matter += "\n---";
      return front_matter
    end
  end

  #
  # Add media content front matter which is consumed by
  # liquid variables in message layout .
  #
  def add_media_content_front_matter(media_content, front_matter)
    begin
      media_content.each do |media|
        #
        # A message can have multiple media contents we need to look for
        # all possiblilities also each media has its own description and title we need them too ..
        #
        case media['ContentTypeID']
          when 5
            # Audio
            audio_description = Contenthelper.purify_by_removing_special_characters(media['Description']);
            audio = media['LowQFilePath'] + media['HighQFilePath'];
            audio_title = Contenthelper.purify_by_removing_special_characters(media['Title']);
            front_matter += "\naudio-description: \"#{audio_description}\"\naudio: \"#{audio}\"\naudio-title: \"#{audio_title}\""
            front_matter += "\naudio-duration: \"#{media['duration']}\"";
          when 4
            # Video -- only IPOD video
            if (media['iPodVideo'].length > 0)
              video_description = Contenthelper.purify_by_removing_special_characters(media['Description']);
              video_title = Contenthelper.purify_by_removing_special_characters(media['Title']);
              video_poster = media['ThumbImagePath'];
              front_matter += "\nvideo-description: \"#{video_description}\"\nvideo-title: \"#{video_title}\""
              front_matter += "\nvideo: \"#{media['iPodVideo']}\"";
              front_matter += "\nvideo-poster: \"#{Immutable.config.image_thumb_base_url}#{video_poster}\"";
            end
          when 7
            # Study Notes
            notes_description = Contenthelper.purify_by_removing_special_characters(media['Description']);
            notes = media['LowQFilePath'] + media['HighQFilePath'];
            notes_title = Contenthelper.purify_by_removing_special_characters(media['Title']);
            front_matter += "\nnotes-description: \"#{notes_description} \"\nnotes: \"#{notes} \"\nnotes-title: \"#{notes_title}\""
          when 8
            # Weekend Program
            if(media['Description'].length > 0)
              program_description = Contenthelper.purify_by_removing_special_characters(media['Description']);
            else
              program_description = '';
            end
            program = media['LowQFilePath'] + media['HighQFilePath'];
            program_title = media['Title'];
            front_matter += "\nprogram-description: \"#{program_description}\"\nprogram: \"#{program}\"\nprogram-title: \"#{program_title}\""
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
      target_file_path = "#{Immutable.config.message_destination_path}/";
      target_file_path += "#{message_data["Title"].downcase.gsub(' ', '_').gsub('/', '-').gsub('?','').gsub('*','').gsub('#','').gsub('@','').gsub('&','_and_')}"
      # lets remove only quotes in the file name since its non standard
      target_file_path += "_#{message_data["Date"].strftime("%Y_%m_%d")}.md";
      # TODO : - put this in a seperate function and make it reusable

      target_file_path = target_file_path.gsub '...', '';
      target_file_path = target_file_path.gsub /'/, '';
      target_file_path = target_file_path.gsub /"/, '';
      target_file_path = target_file_path.gsub '|', '';
      target_file_path = target_file_path.gsub ':', '';
      target_file_path = target_file_path.gsub '__', '_';
      target_file_path = target_file_path.gsub '_-_', '_';
      target_file_path = target_file_path.gsub ',_', '_';
      target_file_path = target_file_path.gsub '_<i>', '_';

      migrated_message_file_handler = File.open(target_file_path, 'w');
      migrated_message_file_handler.write(jekyll_front_matter);
    end
  end


end