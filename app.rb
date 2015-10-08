require 'sinatra'
require './podio_api'


# To avoid using a full database, a list of Trainer objects is saved on disk
File.open('saved_trainers.marshal') do |f|
    # TODO: Should not be reassigning to a constant variable
    SAVED_TRAINERS = Marshal.load(f)
end


def updated_trainers()
    trainers = Array.new

    active = PodioAPI.active_trainers()

    active.each do |t|
        trainer = Trainer.new(t)
        trainers.push(trainer)
    end

    trainers.sort!

    File.open('saved_trainers.marshal', 'w+') do |f|
        Marshal.dump(trainers, f)
    end

    # Thread.new {
    #     active.each do |t|
    #         PodioAPI.download_photo(t)
    #     end
    # }

    return trainers
end


# Render /views/index.erb, the main page for this site
get '/' do
    training_areas = []
    regions = []

    SAVED_TRAINERS.each do |t|
        t.functions_can_train_in.each do |area|
            training_areas.push(area) unless training_areas.include?(area)
        end

        regions.push(t.region) unless regions.include?(t.region)
    end

    regions.sort!

    # Strange this makes it sorted in: General, Basic, Advanced order
    training_areas.sort!.reverse!

    erb :index, :locals => { :trainers => SAVED_TRAINERS,
                             :training_areas => training_areas,
                             :regions => regions }
end


# Connect to Podio and pull down fresh information for all trainers
# Save on disk to saved_trainers.marshal
get '/update' do
    begin
        SAVED_TRAINERS = updated_trainers()
    rescue Podio::RateLimitError => error
        # If we hit the rate limit, print error
        return "You're making too many requests to Podio: " + error.message
    end

    return 'Updating page. Images may take time to update.'
end


# Print all trainers currently in memory on server
get '/trainers' do
    trainers_string = ''

    SAVED_TRAINERS.each do |t|
        trainers_string += '<a href="' + request.base_url + '/update/' + t.id + '">'
        trainers_string += t.to_s
        trainers_string += '</a><br />'
    end

    return trainers_string
end


# Update the photo for the trainer with this ID
get '/update/:id' do
    t = PodioAPI.get_trainer(params['id'])
    PodioAPI.download_photo(t)
    return 'Photo should be updated!'
end
