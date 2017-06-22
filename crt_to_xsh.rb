require 'fileutils'

$rootDir = Dir.getwd

def get_host_name(atmp)
    begin
        type = 0
        hostname = atmp.match(/.*\"Hostname\"=(.*)\n.*/).captures.first
    rescue ArgumentError => e
        type = 1
        atmp = atmp.force_encoding("UTF-16LE")
        hostnameRegex = Regexp.new(".*\"Hostname\"=(.*)\r\n.*".encode(atmp.encoding))
        hostname = atmp.match(hostnameRegex).captures.first
    end
    return hostname, type
end

def get_port(atmp, type)
    case type
    when 0
        begin
            port = atmp.match(/.*SSH2.*Port.*=(.*)\n.*/).captures.first.hex
        rescue
            port = 22
        end
    when 1
        portRegex = Regexp.new(".*SSH2.*Port.*=(.*)\r\n.*".encode('UTF-16LE'))
        begin
            port = atmp.match(portRegex).captures.first.encode!('GBK', 'UTF-16LE', :invalid => :replace, :replace => '').hex
        rescue
            port = 22
        end
    else
        port = 22
    end
    return port.to_s
end

def get_newc(atmp, hostname, port, type)
    text = File.read(File.join($rootDir,"template.xsh"));
    case type
    when 0
        new_c = text.gsub(/HOST_TO_CHANGE/, hostname.encode!('GBK', 'UTF-8', :invalid => :replace, :replace => ''))
        new_c = new_c.gsub(/PORT_TO_CHANGE/, port.encode!('GBK'))
    when 1
        new_c = text.gsub(/HOST_TO_CHANGE/, hostname.encode!('GBK', 'UTF-16LE', :invalid => :replace, :replace => ''))
        new_c = new_c.gsub(/PORT_TO_CHANGE/, port.encode!('GBK'))
    else
        new_c = error
    end
    return new_c
end

def create_dir_if_not_exist(toCreateDir)
    if not Dir.exists?(toCreateDir)
        FileUtils.mkdir_p(toCreateDir)
    end
end


targetDir = File.join($rootDir, "crt_session/Sessions")
Dir.chdir(targetDir)
allDir = Dir.glob("**/*").select {|f| File.directory? f}
allCfg = Dir.glob("**/*.*.*.*.ini")

haoxianDir = File.join($rootDir, "haoxian")

create_dir_if_not_exist(haoxianDir)

Dir.chdir(haoxianDir)

File.open("folder.ini", "w") { |file| file.write("[State]\nExpanded=0")}




allDir.each do |x|
    create_dir_if_not_exist(File.join(haoxianDir, x));
    FileUtils.cp("folder.ini", File.join(haoxianDir, x, "folder.ini"));
end


allCfg.each do |x|
    atmp = File.read(File.join(targetDir, x));
    hostname, type = get_host_name(atmp)
    port = get_port(atmp, type)
    new_c = get_newc(atmp, hostname, port, type)
    File.open(File.join(haoxianDir , x).gsub(/\.ini/, ".xsh"), "w") {|file| file.puts new_c };
end

