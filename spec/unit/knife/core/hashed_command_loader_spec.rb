#
# Copyright:: Copyright (c) 2015 Chef Software, Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Chef::Knife::SubcommandLoader::HashedCommandLoader do
  before do
    allow(ChefConfig).to receive(:windows?) { false }
  end

  let(:plugin_manifest) {
    {
      "_autogenerated_command_paths" => {
        "plugins_paths" => {
          "cool_a" => ["/file/for/plugin/a"],
          "cooler_b" => ["/file/for/plugin/b"],
        },
        "plugins_by_category" => {
          "cool" => [
            "cool_a"
          ],
          "cooler" => [
            "cooler_b"
          ],
        },
      }
    }
  }

  let(:loader) { Chef::Knife::SubcommandLoader::HashedCommandLoader.new(
    File.join(CHEF_SPEC_DATA, "knife-site-subcommands"),
    plugin_manifest)}

  describe "#list_commands" do
    it "lists all commands by category when no argument is given" do
      expect(loader.list_commands).to eq({"cool" => ["cool_a"], "cooler" => ["cooler_b"]})
    end

    it "lists only commands in the given category when a category is given" do
      expect(loader.list_commands("cool")).to eq({"cool" => ["cool_a"]})
    end
  end

  describe "#subcommand_files" do
    it "lists all the files" do
      expect(loader.subcommand_files).to eq(["/file/for/plugin/a", "/file/for/plugin/b"])
    end
  end

  describe "#load_commands" do
    before do
      allow(Kernel).to receive(:load).and_return(true)
    end

    it "returns false for non-existant commands" do
      expect(loader.load_command(["nothere"])).to eq(false)
    end

    it "loads the correct file and returns true if the command exists" do
      allow(File).to receive(:exists?).and_return(true)
      expect(Kernel).to receive(:load).with("/file/for/plugin/a").and_return(true)
      expect(loader.load_command(["cool_a"])).to eq(true)
    end
  end

  describe "#subcommand_for_args" do
    it "returns the subcommands for an exact match" do
      expect(loader.subcommand_for_args(["cooler_b"])).to eq("cooler_b")
    end

    it "finds the right subcommand even when _'s are elided" do
      expect(loader.subcommand_for_args(["cooler", "b"])).to eq("cooler_b")
    end

    it "returns nil if the the subcommand isn't in our manifest" do
      expect(loader.subcommand_for_args(["cooler c"])).to eq(nil)
    end
  end
end
