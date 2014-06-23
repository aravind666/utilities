require_relative 'helper_spec.rb'

describe Series do
  describe '::get_all_series' do
    it 'Get all series content from DB' do
      expect(Mediahelper.get_all_series).to be_an_instance_of(DBI::StatementHandle)
    end
  end
  describe 'series class' do
    #@series = Series.new
    it 'check the instance of series class' do
      #expect(@series).to be_an_instance_of(Series)
    end
  end
end