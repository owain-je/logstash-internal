require 'open3'
require 'fileutils'
require 'json'

#setup some variables 

def get_env(env_name,default_value)
  if(ENV[env_name].to_s != '')
    return ENV[env_name]
  end
  return default_value
end

region = get_env('AWS_REGION',"eu-west-1")
container_name = get_env('NAME',"logstash-internal")
aws_account = get_env('AWS_ACCOUNT',"1234567890")
version = get_env('GO_PIPELINE_LABEL',"1.0")
repository = get_env('REPOSITORY',"#{aws_account}.dkr.ecr.#{region}.amazonaws.com")
registry_ids = ENV['AWS_ACCOUNT']
base_tag="demo/#{container_name}"
version_tag="#{base_tag}:#{version}"
latest_tag="#{base_tag}:latest"
repo_latest_tag="#{repository}/#{latest_tag}"
repo_latest_version_tag="#{repository}/#{version_tag}"

logstash_download_url=get_env('LOGSTASH_DOWNLOAD_URL',"https://artifacts.elastic.co/downloads/logstash/logstash-5.1.1.tar.gz")
elastic_version=get_env('ELASTIC_VERSION',"5.1.1")


module Utils
  class Subprocess
    def initialize(cmd, &block)
      Open3.popen3(cmd) do |stdin, stdout, stderr, thread|
        { :out => stdout, :err => stderr }.each do |key, stream|
          Thread.new do
            until (line = stream.gets).nil? do
              if key == :out
                yield line, nil, thread if block_given?
              else
                yield nil, line, thread if block_given?
              end
            end
          end
        end
        thread.join # don't exit until the external process is done
        exit_code = thread.value
    if(exit_code != 0)
      puts("Failed to execute_cmd #{cmd} exit code: #{exit_code}")
      Kernel.exit(false)
    end
      end
    end
  end
end

def execute_cmd(cmd,chdir=File.dirname(__FILE__))
  puts("execute_cmd: #{cmd}") 
  Utils::Subprocess.new cmd do |stdout, stderr, thread|
      puts "\t#{stdout}"
      if(stderr.nil? == false)
        puts "\t#{stderr}"  
      end
  end
end


def is_automated_build()
  return (ENV['GO_PIPELINE_LABEL'].nil? == false)
end

puts(base_tag)
puts(version_tag)
puts(latest_tag)
puts(repo_latest_tag)
puts(repo_latest_version_tag)
#tasks

task :default => [:inject_labels,:login,:create_repo,:build,:repository_tag,:push]

task :inject_labels do 
  if(is_automated_build())
    lines = File.readlines('Dockerfile')
    lines << "LABEL build-by=\"automation\" \\
                    build-git=\"#{`git rev-parse --verify HEAD`.chomp}\" \\
                    build-pipeline_name=\"#{ENV['GO_PIPELINE_NAME']}\" \\
                    build-pipeline_version=\"#{version}\" \\   
                    build-date=\"#{Time.now.getutc}\" \\
                    build-name=\"#{container_name}\" \\
                    vendor=\"onzo.com\" \\
                    license=\"restricted\"                       
                  "
    File.open("Dockerfile", "w+") do |f|
      f.puts(lines)
    end
  end
end

task :create_repo do 
  if(is_automated_build())
    found = false
    data = `aws ecr --region #{region} describe-repositories`
    json = JSON.parse(data) 
    json['repositories'].each do |repo|
      if repo['repositoryName'] == base_tag
        found = true
        puts("repository already exists #{base_tag}")
        break
      end
    end
    if(!found)
      execute_cmd("aws ecr create-repository --region #{region} --repository-name #{base_tag}")   
    end
  end
end

task :build do
   puts("Building #{base_tag}")
   execute_cmd("docker build --build-arg LOGSTASH_DOWNLOAD_URL=#{logstash_download_url} --build-arg ELASTIC_VERSION=#{elastic_version} -t #{base_tag} .")
end

task :login do 
  login = `aws ecr get-login --region #{region} --no-include-email --registry-ids #{registry_ids}`
  system(login)
end

task :repository_tag do 
    execute_cmd("docker tag #{latest_tag} #{repo_latest_tag}")
    execute_cmd("docker tag #{latest_tag} #{repo_latest_version_tag}")
end

task :push do
    if(is_automated_build())
      execute_cmd("docker push #{repo_latest_tag}")
      execute_cmd("docker push #{repo_latest_version_tag}")
    end
end

task :git_tag do 
  execute_cmd("git tag #{ENV['GO_PIPELINE_LABEL']}")
  execute_cmd("git push origin #{ENV['GO_PIPELINE_LABEL']}")
end 