# encoding: ASCII-8BIT

# message class which defines various attributes and behaviours which are used in
# message migration
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
#
class Message

  #
  # Create Content object by initilizing the migration flow
  #
  def initialize
    self.migrate_messages();
  end

  #
  # This method actually migrates the content by creating the front matter
  #
  def migrate_messages
    begin
      series_data = self.get_all_series();
      self.process_series_data(series_data);
    end
  end

  #
  # This method is used to get all series from database
  #
  def get_all_series
    begin
      series_data = Immutables.dbh.execute('select * from series order by `StartDate` DESC');
      return series_data;
    rescue DBI::DatabaseError => e
      Immutables.log.error "Error code: #{e.err}"
      Immutables.log.error "Error message: #{e.errstr}"
      Immutables.log.error "Error SQLSTATE: #{e.state}"
      abort('An error occurred while getting series data from DB, Check migration log for more details');
    end
  end

  #
  # This method is used to get all messages with in a particular series
  #
  def get_all_messages_for_series(series_id)
    begin
      message_data = Immutables.dbh.execute("select * from message where SeriesID = #{series_id} order by date desc");
      return message_data;
    rescue DBI::DatabaseError => e
      Immutables.log.error "Error code: #{e.err}"
      Immutables.log.error "Error message: #{e.errstr}"
      Immutables.log.error "Error SQLSTATE: #{e.state}"
      abort('An error occurred while getting message data for series from DB, Check migration log for more details');
    end
  end

  #
  # This method gets mediacontent for each messages
  #
  def get_media_content_for_message(message_id)
    begin
      message_media_content_data = Immutables.dbh.execute("SELECT * from mediacontent
where mediacontentid in (select messagemediacontent.mediaid from messagemediacontent where messageid = #{message_id}) AND ( HighQFilePath IS NOT NULL OR iPodVideo IS NOT NULL)");
      return message_media_content_data;
    rescue DBI::DatabaseError => e
      Immutables.log.error "Error code: #{e.err}"
      Immutables.log.error "Error message: #{e.errstr}"
      Immutables.log.error "Error SQLSTATE: #{e.state}"
      abort('An error occurred while getting message media content data from DB, Check migration log for more details');
    end
  end

  #
  # This method will process series data by collecting all its respective messages
  #
  def process_series_data(series_data)
    begin
      series_data.each do |series|
        message_data = self.get_all_messages_for_series(series[0]);
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
        media_content = self.get_media_content_for_message(message[0]);
        if media_content.column_names.size === 0 then
          Immutables.log.info "Message  #{message[0]} does not have any media content";
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
      mainTitle = message_data[2].gsub /"/, '';
      mainTitle = message_data[2].gsub /<i>/,'';
      front_matter = "---\nlayout: message\ncategory: message\nseries: \"#{series[1]}\"\ntitle: \"#{mainTitle}\"";
      front_matter += "\ndate: #{message_data["Date"].strftime("%Y-%m-%d")}"
      return self.add_media_content_front_matter(media_content,front_matter);
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
            audio_description = self.purify_by_removing_special_characters(media['Description']);
            audio = media['LowQFilePath'] + media['HighQFilePath'];
            audio_title = self.purify_by_removing_special_characters(media['Title']);
            front_matter += "\naudio-description: \"#{audio_description}\"\naudio: \"#{audio}\"\naudio-title: \"#{audio_title}\""
            front_matter += "\naudio-duration: \"#{media['duration']}\"";
          when 4
            # Video -- only IPOD video
            if (media['iPodVideo'].length > 0)
              video_description = self.purify_by_removing_special_characters(media['Description']);
              video_title = self.purify_by_removing_special_characters(media['Title']);
              video_poster = media['ThumbImagePath'];
              front_matter += "\nvideo-description: \"#{video_description}\"\nvideo-title: \"#{video_title}\""
              front_matter += "\nvideo: \"#{media['iPodVideo']}\"";
              front_matter += "\nvideo-poster: \"#{Immutables.config.image_thumb_base_url}#{video_poster}\"";
            end
          when 7
            # Study Notes
            notes_description = self.purify_by_removing_special_characters(media['Description']);
            notes = media['LowQFilePath'] + media['HighQFilePath'];
            notes_title = self.purify_by_removing_special_characters(media['Title']);
            front_matter += "\nnotes-description: \"#{notes_description} \"\nnotes: \"#{notes} \"\nnotes-title: \"#{notes_title}\""
          when 8
            # Weekend Program
            program_description = self.purify_by_removing_special_characters(media['Description']);
            program = media['LowQFilePath'] + media['HighQFilePath'];
            program_title = self.purify_by_removing_special_characters(media['Title']);
            front_matter += "\nprogram-description: \"#{program_description}\"\nprogram: \"#{program}\"\nprogram-title: \"#{program_title}\""
        end
      end
      front_matter += "\n---";

      return front_matter;
    end
  end


  #
  # Creates a jekyll page by applying neccessary frontmatter
  #
  def migrate_by_adding_jekyll_front_matter(jekyll_front_matter, message_data)
    begin
      target_file_path = "#{Immutables.config.message_destination_path}/";
      target_file_path += "#{message_data["Title"].downcase.gsub(' ', '_').gsub('/', '-').gsub('?','')}.md"
      # lets remove only quotes in the file name since its non standard
      target_file_path.gsub /"/, '';
      migrated_message_file_handler = File.open(target_file_path, 'w');
      migrated_message_file_handler.write(jekyll_front_matter);
    end
  end

  #
  # Thanks to Dan Rye for giving this beatiful thing
  # This method replaces junk characters with alternative symbols
  #
  def purify_by_removing_special_characters(string_to_purify)

    replacements = []
    replacements << ['â€¦', '…'] # elipsis
    replacements << ['â€“', '–'] # long hyphen
    replacements << ['â€”', '–'] # long hyphen
    replacements << ['â€™', '’'] # curly apostrophe
    replacements << ['â€œ', '“'] # curly open quote
    replacements << [/â€[[:cntrl:]]/, '”'] # curly close quote
    replacements << [':', '&#58;'] # escape colon
    replacements << ['\C-M', ''] # remove unwanted control m chars
    replacements << ['Â', ''] # remove nbsp character
    replacements << ['"', '\\"'] # escape quotes

    replacements.each { |set| string_to_purify = string_to_purify.gsub(set[0], set[1]) }
    return string_to_purify
  end

end