require "option_parser"
require "baked_file_system"
require "html"

module Abc2html
   VERSION = "1.0.0"

   class FileStorage extend BakedFileSystem
      bake_folder "../abcjs"
   end

   class Melodie
      @lines: Array(String)
      
      def initialize
         @lines = Array(String).new
      end
      
      def add_line(ln : String)
         @lines << ln
      end

      def show(nr : Int32)
         puts "   melodie #{nr}"
         
         @lines.each do |line|
            puts "      line #{line}"
         end
      end

      def has_number?
         hasn = false
         @lines.each do |line|
            if line.starts_with?("X:")
               hasn = true
            end
         end
         hasn
      end

      def oneline
         lijn = ""
         @lines.each do |line|
            if !line.empty?
               lijn = lijn + line
               lijn = lijn + "\\n"
            end
         end
         #puts "      lijn #{lijn}"
         lijn
      end
   end

   class Bestand
      @name:      String
      @file:      File
      @lines:     Array(String)
      @melodieen: Array(Melodie)
      
      getter name
      getter file
      getter melodieen
      
      def initialize(@name : String, @file : File)
         puts "new file #{@name}"
         @lines = File.read_lines(@file.path)
         @melodieen = Array(Melodie).new
         
         mel = Melodie.new
         first = true
         @lines.each do |line|
            if !line.empty?
               mel.add_line(line)
               first = true
            else
               if first
                  if mel.has_number?
                     @melodieen << mel
                  end
                  mel = Melodie.new
                  first = false
               end
            end
         end         
      end
      
      def size
         @melodieen.size
      end

      def show
         puts "   bestand #{@name}"
         
         @lines.each do |line|
            puts "      line #{line}"
         end

         puts "---- melodieen ----"
         nr = 1
         @melodieen.each do |mel|
            mel.show nr
            nr = nr + 1
         end
      end

      def oneline
         #puts "   html bestand #{@name}"
         
         #@lines.each do |line|
         #   puts "      line2 #{line}"
         #end
         
         lijn = ""
         @lines.each do |line|
            if !line.empty?
               lijn = lijn + line
               lijn = lijn + "\\n"
            end
         end
         #puts "      lijn #{lijn}"
         lijn
      end
   end

   class Muziek
      @bestanden: Array(Bestand)
      
      def initialize
         @bestanden = Array(Bestand).new
      end
      
      # add a file
      def add(best : Bestand)
         @bestanden << best
      end
      
      def size
         sz = 0
         @bestanden.each do |best|
            sz += best.size
         end
         sz
      end

      def get_melodieen
         mels = Array(Melodie).new
         @bestanden.each do |best|
            best.melodieen.each do |mel|
               mels << mel
            end
         end
         mels         
      end

      def show
         puts "---- muziek ----- size #{size}"
         @bestanden.each do |best|
            best.show
         end
      end

      def escape(s : String)
         s2 = ""
         s.each_char do |ch|
            if ch == '\''
               s2 = s2 + '\\'
               s2 = s2 + ch
            else
               s2 = s2 + ch
            end
         end
         s2
      end
      
      def to_html_oud(f : File)
         # write the html header
         f.puts "#{html1}"
         
         # write the div's
         (1..@bestanden.size).each do |nr|
            f.puts "  <h2>Melodie #{nr}</h2>"
            f.puts "  <div id=\"notation#{nr}\"></div>"
            f.puts "  <div id=\"audio#{nr}\"></div>"
            f.puts ""
         end

         # write the script element
         f.puts "#{html2}"
         
         nr = 1
         @bestanden.each do |best|
            #f.puts "var abc#{nr} = \'#{best.oneline}\'"
            f.puts "var abc#{nr} = \'#{escape best.oneline}\'"
            nr += 1
         end
         f.puts ""
         
         # write the 2 Javascript functions
         f.puts "#{html3}"
         f.puts ""
         
         # write the function calls
         (1..@bestanden.size).each do |nr|
            f.puts "onRender(\"notation#{nr}\", \"audio#{nr}\", abc#{nr});"
            f.puts "onMidi(\"notation#{nr}\", \"audio#{nr}\", abc#{nr});"
         end

         f.puts "#{html4}"
      end

      def to_html(f : File)
         # write the html header
         f.puts "#{html1}"
         
         # write the div's
         (1..get_melodieen.size).each do |nr|
            f.puts "  <h2>Melodie #{nr}</h2>"
            f.puts "  <div id=\"notation#{nr}\"></div>"
            f.puts "  <div id=\"audio#{nr}\"></div>"
            f.puts ""
         end

         # write the script element
         f.puts "#{html2}"
         
         nr = 1
         get_melodieen.each do |mel|
            f.puts "var abc#{nr} = \'#{escape mel.oneline}\'"
            nr += 1
         end
         f.puts ""
         
         # write the 2 Javascript functions
         f.puts "#{html3}"
         f.puts ""
         
         # write the function calls
         (1..get_melodieen.size).each do |nr|
            f.puts "onRender(\"notation#{nr}\", \"audio#{nr}\", abc#{nr});"
            f.puts "onMidi(\"notation#{nr}\", \"audio#{nr}\", abc#{nr});"
         end

         f.puts "#{html4}"
      end
      
      
      def html1
"<!DOCTYPE HTML>
<html>
<head>
   <meta charset='utf-8'>
   <meta http-equiv=\"content-type\" content=\"text/html\" />
   <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
   <link rel=\"icon\" href=\"favicon.ico\" type=\"image/x-icon\"/>
   <title>abcjs basic demo</title>
   <link href=\"abcjs-audio.css\" media=\"all\" rel=\"stylesheet\" type=\"text/css\" />
   <script src=\"abcjs-basic-min.js\" type=\"text/javascript\"></script>
   <style>
      .abcjs-inline-audio {
         max-width: 770px;
      }
   </style>
</head>
<body>
  <h1>Muziek</h1>"
      end
      
      def html2
         "<script type=\"text/javascript\">"
      end
      
      def html3
"
function onMidi(notel, auel, tune)
{
   if (ABCJS.synth.supportsAudio())
   {
      var visualObj = ABCJS.renderAbc(notel, tune)[0];
      var synthControl = new ABCJS.synth.SynthController();
      synthControl.load(\"#\" + auel, null, {displayRestart: true, displayPlay: true, displayProgress: true, displayWarp: true});
      synthControl.setTune(visualObj, false);
   } 
   else
   {
      document.querySelector(\"#\" + auel).innerHTML = \"<div class='audio-error'>Audio is not supported in this browser.</div>\";
   }
}


function onRender(notel, auel, tune, params)
{
   if (!params)
   {
      params = {};
   }
   ABCJS.renderAbc(notel, tune, params);
   document.getElementById(auel).innerHTML = \"\";
}
"
      end

      def html4
"</script>
</body>
</html>
"
      end
   end

   class Main
      @muziek: Muziek
      
      def initialize
         @ls       = false
         @info     = false
         @muziek   = Muziek.new
      end

      def get_options
         option_parser = OptionParser.parse do |parser|
            parser.banner = "Welcome to abc2html!"
      
            parser.on "-v", "--version", "Show version" do
               puts "version 1.0.0"
               exit
            end
            parser.on "-h", "--help", "Show help" do
               puts parser
               exit
            end
            parser.on "-l", "--ls", "list files" do
               @ls = true
            end
            parser.on "-i", "--info", "extra info" do
               @info = true
            end
            parser.missing_option do |option_flag|
               STDERR.puts "ERROR: #{option_flag} is missing something."
               STDERR.puts ""
               STDERR.puts parser
               exit(1)
            end
            parser.invalid_option do |option_flag|
               STDERR.puts "ERROR: #{option_flag} is not a valid option."
              STDERR.puts parser
              exit(1)
            end
         end
      end
      
      def lsdir(curdir : String)
          if @info
             puts curdir
          end

          dir = Dir.new(curdir)
          #puts dir.path
          
          dir.each do |fn|
             if File.file?("#{dir.path}/#{fn}")
                f = File.new("#{dir.path}/#{fn}")
                if @info
                   puts "file ##{dir.path}/#{fn}"
                   
                   #puts "basename #{File.basename(f.path)}"
                   bname = File.basename(f.path)
                   puts "basename #{bname}"
                   parts = bname.split(".")
                   
                   isabc = false
                   parts.each do |part|
                      puts "   part #{part}"
                      if part == "abc"
                         isabc = true
                         puts "      abc"
                      else
                         isabc = false
                      end
                   end
                   
                   if isabc
                      @muziek.add(Bestand.new(bname, f))
                   end
                end
                
             else
                if fn != "." && fn != ".."
                   #puts "dir #{fn}"
                   if Dir.exists?("#{dir.path}/#{fn}")
                      #puts "is dir"
                      #lsdir("#{dir.path}/#{fn}")
                   end
                end
             end
          end
      end

      def ls
         curdr = "."
         lsdir(curdr)
         if @info
            #@muziek.show
            
            nr = 1
            @muziek.get_melodieen.each do |mel|
               mel.show nr
               nr += 1
            end
         end

         fuit = File.new("abc.html", "w")
         @muziek.to_html fuit
         fuit.close
          
         # write css file
         fscss = FileStorage.get("abcjs-audio.css")
         css = fscss.gets_to_end       # returns content of file
         #puts "css #{file.path}" # returns path of file
         #file.size              # returns size of original file         
         fcss = File.new("abcjs-audio.css", "w")
         fcss.puts "#{css}"
         fcss.close

         # write js file
         fsjs = FileStorage.get("abcjs-basic-min.js")
         js = fsjs.gets_to_end       # returns content of file
         fjs = File.new("abcjs-basic-min.js", "w")
         fjs.puts "#{js}"
         fjs.close
      end
      
      def run
         get_options
         if @info
            puts "with info"
         end
         if @ls
            puts "with ls"
            ls
         end

         
      end
   end
  
   # TODO: Put your code here
   main = Main.new
   main.run
end
   
