require 'streamio-ffmpeg'

class MusicConverter
  
  attr_reader :accepted_ext
  attr_reader :music_folder, :map_songs

  def initialize
    @accepted_folders = ['music', 'musica', 'música']
    @accepted_ext = ['aac', 'm4a', 'mp3', 'ogg']
    @map_songs = {}
    @overwrite = false
    searchMusicFolder
    puts "Music folder -> " << @music_folder
    collectMusic
    
  end

  Song = Struct.new(:name, :ext, :path) do
    def name_no_ext
      path + "/" + name
    end
    def to_s
      "#{path}/#{name}.#{ext}"
    end
    def eql? (another_song)
      name.eql? another_song.name or ext.eql? song.ext
    end
  end

  def printMusic
    collectMusic
    @map_songs.each do |key, array|
      puts "\n::: #{key.to_s} :::"
      array.sort_by{|s| s.path}.each do |song|
        puts song.to_s
      end
    end
    puts "\n\n"
  end

  def convert(song, output_ext)
    if accepted_ext.include? output_ext
      ffmpeg_object = FFMPEG::Movie.new( song.to_s )

      unless song.ext.eql? output_ext
        output = song.name_no_ext + "." + output_ext
        ffmpeg_object.transcode(output)
        puts song.to_s << " -> " << output
      end
    end
  end

  def convertAll(output_ext)
    @map_songs.each do |key, array|
      unless key.to_s == output_ext
        threads = []
        array.each do |song|
          threads << Thread.new do
            convert(song, output_ext)
          end
        end

        threads.each do |thread|
          thread.join
        end
        puts "\n ¡¡¡DONE!!! \n"
        printMusic        
      end
    end
  end

  def exist? (song)
    if song.is_a? String
      song = parseSong(song)
    end
    @map_songs[song.ext].any? { |a_song| song.eql? a_song}
  end

  def parseSong(song)
    ext = song.split('.').last
    path = song.split('/')[0...-1].join('/')
    name = song.split('/').last.split('.').first
    Song.new(name,ext,path)
  end

  private 
  def searchMusicFolder
    Dir.foreach(Dir.home) do |elem|
      if @accepted_folders.include? elem.downcase
        @music_folder = "#{Dir.home}/#{elem}"
      end
    end
  end

  def collectMusic
    @map_songs = {}
    Dir[@music_folder+'/**/*.*'].each do |a_string|
        mySong = parseSong(a_string)

        
        @map_songs[mySong.ext] = Array.new unless @map_songs.key? mySong.ext
        
        @map_songs[mySong.ext] << mySong
    end
  end
end
 
convertidor = MusicConverter.new
convertidor.printMusic
print "Convertir a { " 
convertidor.accepted_ext.each {|e| print "#{e} "}
print " } => "
ext_out = gets.chomp

if convertidor.accepted_ext.include? ext_out
  convertidor.convertAll(ext_out)
else
  puts "Extensión no soportada"
end
