# encoding: ASCII-8BIT
#
# message class which defines various attributes and behaviours which are used in
# message migration
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Initiating this class leads to migration of messages content
#
class Message

  #
  # Initializing the message content migration process
  #
  def initialize
    self.migrate_messages;
  end

  # Public: migrate message content
  #
  # Get all series from DB
  # to generate message content jekyll front matter
  #
  def migrate_messages
    begin
      series_data = Mediahelper.get_all_series;
      self.process_series_data(series_data);
    end
  end

  # Public: process series data by collecting all its respective messages
  #
  # *series_data* - array of series content records
  #
  # Returns success message
  #
  def process_series_data(series_data)
    begin
      series_data.each do |series|
        message_data = Mediahelper.get_all_messages_for_series(series[0]);
        process_message_data(message_data, series);
      end
      abort('Successfully migrated messages in specified destination')
    end
  end

  # Public: process message details to generate jekyll front matter
  #
  # *message_data* - Array message data
  # *series* - Array series data
  # Returns the front matter YAML for the message
  # which is about to get migrated
  #
  def process_message_data(message_data, series)
    begin
      message_data.each do |message|
        media_content = Mediahelper.get_media_content_for_message(message[0]);
        media_content_structure = media_content.fetch_all;
        if media_content_structure.size == 0 then
          Immutable.log.info "Message  #{message[0]} does not have any media content";
        else
          front_matter = self.get_jekyll_frontmatter_for_messages(message, series, media_content_structure);
          self.migrate_by_adding_jekyll_front_matter(front_matter, message);
        end
      end
    end
  end

  # Public: prepares jekyll front matter for message content
  #
  # *message_data* - Array message data to prepare jekyll front matter
  # *series* - Array series data need to prepare jekyll front matter
  # *media_content_structure* - Array media content data
  #
  # Returns message content jekyll front matter
  #
  def get_jekyll_frontmatter_for_messages(message_data, series, media_content_structure)
    begin
      front_matter = '';
      mainTitle = message_data[2].gsub /"/, '';
      front_matter = "---\nlayout: message\ncategory: message\nseries: \"#{series[1]}\"\ntitle: \"#{mainTitle}\"";
      front_matter += "\ndate: #{message_data["Date"].strftime("%Y-%m-%d-%H-%M")}";
      front_matter += "\nmessage_id: #{message_data[0]}";
      front_matter = self.add_media_content_front_matter(media_content_structure, front_matter, message_data[0]);
      front_matter += "\n---";
      return front_matter;
    end
  end

  # Public: prepares jekyll front matter for message media content
  #
  # *media_content_structure* - String message data to prepare jekyll front matter
  # *front_matter* - String series jekyll front matter
  # *message_id* - Int message id used in front matters
  #
  # Returns message media content jekyll front matter
  #
  def add_media_content_front_matter(media_content_structure, front_matter, message_id)
    begin
      explicit = ''
      media_content_structure.each do |media|
        lq_file_path = media['LowQFilePath'];
        #
        # A message can have multiple media contents we need to look for
        # all possibilities also each media has its own description and title we need them too
        #

        if media['isAdult'] == 'N' || media['isAdult']==''
          explicit = false
        else
          explicit = true
        end
        case media['ContentTypeID']
          when 5
            # Audio
            if (media['HighQFilePath'].length > 0)
              if (lq_file_path['www.crossroads.net'])
                audio_file_path = lq_file_path.gsub('http://www.crossroads.net/', '/');
                audio_file_path = lq_file_path.gsub('https://www.crossroads.net/', '/');
                audio_file_path = "#{Immutable.config.s3media}/mp3/#{ContentHelper.encode_url_string(media['HighQFilePath'])}";
              else
                audio_file_path = "#{lq_file_path}#{ContentHelper.encode_url_string(media['HighQFilePath'])}"
              end
              front_matter += "\naudio: \"#{audio_file_path}\"";
              front_matter += "\naudio-duration: \"#{media['duration']}\"";
            end
          when 4
            # Video -- only IPOD video
            if (media['iPodVideo'].length > 0)
              video_description = ContentHelper.purify_by_removing_special_characters(media['Description']);
              video_title = ContentHelper.purify_by_removing_special_characters(media['Title']);
              video_poster = media['ThumbImagePath'];
              if !media['duration'] || media['duration'] == ':' || media['duration'].to_s.nil?
                audio_duration = Mediahelper.get_audio_duration(message_id);
                media['duration'] = audio_duration['duration'];
              end
              front_matter += "\ndescription: \"#{video_description}\"";
              front_matter += "\nvideo: \"#{media['iPodVideo']}\"\nvideo-duration: \"#{media['duration']}\"";
              front_matter += "\nvideo-image: \"#{Immutable.config.s3url}/content/#{video_poster}\"";
            end
          when 7
            # Study Notes
            notes_description = ContentHelper.purify_by_removing_special_characters(media['Description']);

            if (lq_file_path['www.crossroads.net'])
              notes_file_path = lq_file_path.gsub('http://www.crossroads.net/', '/');
              notes_file_path = lq_file_path.gsub('https://www.crossroads.net/', '/');
              notes_file_path = "#{Immutable.config.s3media}/documents/#{ContentHelper.encode_url_string(media['HighQFilePath'])}"
            else
              notes_file_path = "#{lq_file_path}#{ContentHelper.encode_url_string(media['HighQFilePath'])}";
            end

            notes_title = ContentHelper.purify_by_removing_special_characters(media['Title']);
            front_matter += "\nnotes-description: \"#{notes_description}\"";
            front_matter += "\nnotes: \"#{notes_file_path}\"\nnotes-title: \"#{notes_title}\"";
          when 8
            # Weekend Program

            if (lq_file_path['www.crossroads.net'])
              program_file_path = lq_file_path.gsub('http://www.crossroads.net/', '/');
              program_file_path = lq_file_path.gsub('https://www.crossroads.net/', '/');
              program_file_path = "#{Immutable.config.s3media}/documents/#{ContentHelper.encode_url_string(media['HighQFilePath'])}"
            else
              program_file_path = "#{lq_file_path}#{ContentHelper.encode_url_string(media['HighQFilePath'])}";
            end

            front_matter += "\nprogram: \"#{program_file_path}\"";
          else
        end
      end
      front_matter += "\nexplicit: #{explicit}";
      return front_matter;
    end
  end

  # Public: creates a jekyll page for message content
  #
  # *jekyll_front_matter* - String message content jekyll front matter to write to the file
  # *message_data* - Array message data to create a file name with title and date
  #
  # Return file by writing the message content front matter to the given destination path
  #
  def migrate_by_adding_jekyll_front_matter(jekyll_front_matter, message_data)
    begin
      target_file_path = "#{Immutable.config.message_destination_path}/";
      title = ContentHelper.purify_title_by_removing_special_characters(message_data['Title'].downcase.strip);
      target_file_path += "#{message_data['Date'].strftime('%Y-%m-%d')}-#{title}.md";
      migrated_message_file_handler = File.open(target_file_path, 'w');
      migrated_message_file_handler.write(jekyll_front_matter);
    end
  end

end
