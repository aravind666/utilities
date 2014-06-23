
require_relative 'helper_spec.rb'

describe ContentHelper do
		
		describe '::directory_exists?' do
		  it 'This checks whether directory exists or not' do
		      expect(ContentHelper.directory_exists? '/var/milacron/').to be true
		  end
    end
    
    describe '::remove_all_special_characters_from_string' do
		  it 'This removes all special characters from the string' do
		      expect(ContentHelper.remove_all_special_characters_from_string 'test#$').to eq('test')
		  end
    end
    
    describe '::remove_file_extension_from_filename' do

		  it 'This removes file extension from file name' do
		      expect(ContentHelper.remove_file_extension_from_filename 'test.md').to eq('test')
		  end
    end
    
    describe '::purify_file_path' do
		  it 'This method removes empty directory(//) from the given path' do
		      expect(ContentHelper.purify_file_path '/var/milacron//classes/').to eq('/var/milacron/classes/')
		  end
    end
    
    describe '::purify_file_path' do
		  it 'This method removes epmty directory(//) from the given path with negative case' do
		      expect(ContentHelper.purify_file_path '/var/milacron/classes/').to eq('/var/milacron/classes/')
		  end
    end
    
    describe '::purify_title_by_removing_special_characters' do
		  it 'This method removes special characters from the given string' do
		      expect(ContentHelper.purify_title_by_removing_special_characters 'Building').to eq('Building')
		  end
    end
       describe '::purify_title_by_removing_special_characters' do
		  it 'This method removes special characters from the given string with negative case' do
		      expect(ContentHelper.purify_title_by_removing_special_characters 'Florence-ttile').to eq('Florence-ttile')
		  end
    end
end


