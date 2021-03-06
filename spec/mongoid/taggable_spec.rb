# Copyright (c) 2010 Wilker Lúcio <wilkerlucio@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class MyModel
  include Mongoid::Document
  include Mongoid::Taggable
end

describe Mongoid::Taggable do

  describe "default tags array value" do
    it 'should be an empty array' do
      MyModel.new.tags_array.should == []
    end
  end

  context "finding" do
    let(:model){MyModel.create!(:tags => "interesting,stuff,good,bad")}
    context "by tagged_with" do
      let(:models){MyModel.tagged_with('interesting')}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_all using an array" do
      let(:models){MyModel.tagged_with_all(['interesting', 'good'])}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_all using strings" do
      let(:models){MyModel.tagged_with_all('interesting', 'good')}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_all when tag not included" do
      let(:models){MyModel.tagged_with_all('interesting', 'good', 'mcdonalds')}
      it "locates tagged objects" do
        models.include?(model).should be_false
      end
    end
    context "by tagged_with_any using an array" do
      let(:models){MyModel.tagged_with_any(['interesting', 'mcdonalds'])}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_any using strings" do
      let(:models){MyModel.tagged_with_any('interesting', 'mcdonalds')}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_any when tag not included" do
      let(:models){MyModel.tagged_with_any('hardees', 'wendys', 'mcdonalds')}
      it "locates tagged objects" do
        models.include?(model).should be_false
      end
    end
  end

  context "saving tags from plain text" do
    before :each do
      @m = MyModel.new
    end

    it "should set tags array from string" do
      @m.tags = "some,new,tag"
      @m.tags_array.should == %w[some new tag]
    end

    it "should retrieve tags string from array" do
      @m.tags_array = %w[some new tags]
      @m.tags.should == "some,new,tags"
    end

    it "should strip tags before put in array" do
      @m.tags = "now ,  with, some spaces  , in places "
      @m.tags_array.should == ["now", "with", "some spaces", "in places"]
    end

    it "should not put empty tags in array" do
      @m.tags = "repetitive,, commas, shouldn't cause,,, empty tags"
      @m.tags_array.should == ["repetitive", "commas", "shouldn't cause", "empty tags"]
    end
  end

  context "changing separator" do
    before :all do
      MyModel.tags_separator ";"
    end

    after :all do
      MyModel.tags_separator ","
    end

    before :each do
      @m = MyModel.new
    end

    it "should split with custom separator" do
      @m.tags = "some;other;separator"
      @m.tags_array.should == %w[some other separator]
    end

    it "should join with custom separator" do
      @m.tags_array = %w[some other sep]
      @m.tags.should == "some;other;sep"
    end
  end
end
