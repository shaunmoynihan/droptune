class FollowJob
  include Sidekiq::Worker

  sidekiq_options :queue => :default

  def perform(id)
    user = User.find id
    connection = user.connections.where(provider:'spotify').first.settings.to_hash
    spotify_user = RSpotify::User.new(connection)

    spotify = spotify_user

    # Saved Tracks
    artist_ids = Array.new
    
    (0..100000000000).step(50) do |n|
      tracks = spotify.saved_tracks(limit: 50, offset: n)
      break if tracks.size == 0
      tracks.each do |track|
        track.artists.each do |artist|
          artist_ids.push(artist.id)
        end
      end
      
      #sleep 0.3
    end

    artist_ids = artist_ids.uniq.compact.each_slice(50).to_a
    artist_ids.each do |artist_group|
      ArtistJob.perform_async(user.id, artist_group)
    end

    # Playlists
    # spotify.playlists.each do |playlist|
    #   artist_ids = Array.new
    #   playlist.tracks.each do |track|
    #     track.artists.each do |artist|
    #       artist_ids.push(artist.id)
    #     end
    #   end
    #   artist_ids = artist_ids.uniq.compact.each_slice(25).to_a
    #   artist_ids.each do |artist_group|
    #     ArtistJob.perform_later(user.id, artist_group)
    #   end
    #   sleep 0.3
    # end
  end
end
