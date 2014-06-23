require_relative 'helper_spec.rb'

describe Mediahelper do
	describe '::get_all_series' do
		it 'Get all series from DB' do
			expect(Mediahelper.get_all_series).to be_an_instance_of(DBI::StatementHandle)
		end
	end
  describe '::get_audio_content' do
    it 'Get all audio content from DB' do
      expect(Mediahelper.get_audio_content).to be_an_instance_of(DBI::StatementHandle)
    end
  end
end
