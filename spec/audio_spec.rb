require_relative 'helper_spec.rb'

describe Audio do
  describe '::get_audio_content' do
    it 'Get all audio content from DB' do
      expect(Mediahelper.get_audio_content).to be_an_instance_of(DBI::StatementHandle)
    end
  end
  describe 'audio class' do
    #@audio = Audio.new
      it 'check the instance of audio class' do
        #expect(@audio).to be_an_instance_of(Audio)
    end
  end
end
