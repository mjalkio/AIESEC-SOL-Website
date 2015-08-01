require 'active_support'
require 'podio'
require './settings'
require 'sinatra/base'

include Settings

### API Functions ###
module PodioAPI
    def self.connect()
        if Podio.connection.nil?
            Podio.setup(:api_key => Settings::client_id, :api_secret => Settings::client_secret)
            Podio.client.authenticate_with_credentials(Settings::username, Settings::user_password)
        end
    end


    def self.active_trainers()
        connect()
        response = Podio::Item.find_by_filter_values(Settings.app_id,
                                                     {'current-status': [1]},
                                                     {'limit': 200})
        return response.all
    end


    def self.active_trainer_item_ids()
        trainers = active_trainers()
        ids = []
        trainers.each do |trainer|
            ids.push(trainer.item_id)
        end

        return ids
    end


    def self.get_trainer(item_id)
        connect()
        return Podio::Item.find(item_id)
    end


    def self.get_single_value_field(trainer, field_id)
        fields = trainer.fields
        fields.each do |field|
            if field['field_id'] == field_id
                return field['values'].first['value']
            end
        end

        return nil
    end


    def self.trainer_name(trainer)
        return get_single_value_field(trainer, 14992170)
    end

    def self.trainer_lc(trainer)
        return get_single_value_field(trainer, 15000638)['text']
    end


    def self.trainer_region(trainer)
        return get_single_value_field(trainer, 85718052)['text']
    end


    def self.trainer_email(trainer)
        return get_single_value_field(trainer, 14992177)
    end


    def self.number_of_trainings(trainer)
        if get_single_value_field(trainer, 84814737).nil?
            return '0'
        else
            return get_single_value_field(trainer, 84814737)['text']
        end
    end


    def self.functions_can_train_in(trainer)
        fields = trainer.fields
        areas = []
        fields.each do |field|
            if field['field_id'] == 84814972
                areas = field['values']
                break
            end
        end

        training_functions = []
        areas.each do |area|
            training_functions.push(area['value']['text'])
        end

        return training_functions
    end


    def self.badges(trainer)
        fields = trainer.fields
        experiences = []
        fields.each do |field|
            if field['field_id'] == 25034685
                experiences = field['values']
                break
            end
        end

        badges = []
        experiences.each do |area|
            badges.push(Badge.new(area['value']['text']))
        end

        return badges
    end


    def self.photo_name(trainer)
        file_field = get_single_value_field(trainer, 14992185)
        if file_field.nil?
            return 'photo_not_found.jpg'
        else
            return file_field['name']
        end
    end


    def self.download_photo(trainer)
        file_field = get_single_value_field(trainer, 14992185)
        unless file_field.nil?
            file_name = file_field['name']
            file_id = file_field['file_id']

            File.open(("public/img/trainer_photos/#{ file_name }"), 'w+') do |downloaded_file|
                f = Podio::FileAttachment.find(file_id)
                downloaded_file.write(Podio.connection.get(f.link + "/extra_large").body)
            end
        end
    end
end


### Trainer Class ###
class Trainer
    include Comparable

    attr_reader :name, :local_committee, :region, :num_trainings, :photo_name, :functions_can_train_in, :badges

    def initialize(trainer)
        @name = PodioAPI.trainer_name(trainer)
        @local_committee = PodioAPI.trainer_lc(trainer)
        @region = PodioAPI.trainer_region(trainer)
        @num_trainings = PodioAPI.number_of_trainings(trainer)
        @photo_name = PodioAPI.photo_name(trainer)
        @functions_can_train_in = PodioAPI.functions_can_train_in(trainer)
        @badges = PodioAPI.badges(trainer)
    end

    def to_s()
        @name + ', ' + @local_committee
    end

    # Order trainings by the number of trainings and then alphabetically
    def <=>(other)
        if (num_trainings <=> other.num_trainings) == 0
            return name <=> other.name
        else
            return other.num_trainings <=> num_trainings
        end
    end
end


### Badge Class ###
class Badge
    attr_reader :name, :image_name

    def initialize(name)
        @name = name
        @image_name = name.downcase.gsub(' ', '_') + '.png'
    end
end
