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
  include Mongoid::Categorizable
end

describe Mongoid::Categorizable do

  describe "default categories array value" do
    it 'should be an empty array' do
      MyModel.new.categories_array.should == []
    end
  end

  context "finding" do
    let(:model){MyModel.create!(:categories => "interesting,stuff,good,bad")}
    context "by categorized_with" do
      let(:models){MyModel.categorized_with('interesting')}
      it "locates categorized objects" do
        models.include?(model).should be_true
      end
    end
    context "by categorized_with_all using an array" do
      let(:models){MyModel.categorized_with_all(['interesting', 'good'])}
      it "locates categorized objects" do
        models.include?(model).should be_true
      end
    end
    context "by categorized_with_all using strings" do
      let(:models){MyModel.categorized_with_all('interesting', 'good')}
      it "locates categorized objects" do
        models.include?(model).should be_true
      end
    end
    context "by categorized_with_all when category not included" do
      let(:models){MyModel.categorized_with_all('interesting', 'good', 'mcdonalds')}
      it "locates categorized objects" do
        models.include?(model).should be_false
      end
    end
    context "by categorized_with_any using an array" do
      let(:models){MyModel.categorized_with_any(['interesting', 'mcdonalds'])}
      it "locates categorized objects" do
        models.include?(model).should be_true
      end
    end
    context "by categorized_with_any using strings" do
      let(:models){MyModel.categorized_with_any('interesting', 'mcdonalds')}
      it "locates categorized objects" do
        models.include?(model).should be_true
      end
    end
    context "by categorized_with_any when category not included" do
      let(:models){MyModel.categorized_with_any('hardees', 'wendys', 'mcdonalds')}
      it "locates categorized objects" do
        models.include?(model).should be_false
      end
    end
  end

  context "saving categories from plain text" do
    before :each do
      @m = MyModel.new
    end

    it "should set categories array from string" do
      @m.categories = "some,new,category"
      @m.categories_array.should == %w[some new category]
    end

    it "should retrieve categories string from array" do
      @m.categories_array = %w[some new categories]
      @m.categories.should == "some,new,categories"
    end

    it "should strip categories before put in array" do
      @m.categories = "now ,  with, some spaces  , in places "
      @m.categories_array.should == ["now", "with", "some spaces", "in places"]
    end

    it "should not put empty categories in array" do
      @m.categories = "repetitive,, commas, shouldn't cause,,, empty categories"
      @m.categories_array.should == ["repetitive", "commas", "shouldn't cause", "empty categories"]
    end
  end

  context "changing separator" do
    before :all do
      MyModel.categories_separator ";"
    end

    after :all do
      MyModel.categories_separator ","
    end

    before :each do
      @m = MyModel.new
    end

    it "should split with custom separator" do
      @m.categories = "some;other;separator"
      @m.categories_array.should == %w[some other separator]
    end

    it "should join with custom separator" do
      @m.categories_array = %w[some other sep]
      @m.categories.should == "some;other;sep"
    end
  end

  context "indexing categories" do
    it "should generate the index collection name based on model" do
      MyModel.categories_index_collection.should == "my_models_categories_index"
    end

    context "retrieving index" do
      before :each do
        MyModel.create!(:categories => "food,ant,bee")
        MyModel.create!(:categories => "juice,food,bee,zip")
        MyModel.create!(:categories => "honey,strip,food")
      end

      it "should retrieve the list of all saved categories distinct and ordered" do
        MyModel.categories.should == %w[ant bee food honey juice strip zip]
      end

      it "should retrieve a list of categories with weight" do
        MyModel.categories_with_weight.should == [
          ['ant', 1],
          ['bee', 2],
          ['food', 3],
          ['honey', 1],
          ['juice', 1],
          ['strip', 1],
          ['zip', 1]
        ]
      end
    end

    context "avoiding index generation" do
      before :all do
        MyModel.disable_categories_index!
      end

      after :all do
        MyModel.enable_categories_index!
      end

      it "should not generate index" do
        MyModel.create!(:categories => "sample,categories")
        MyModel.categories.should == []
      end
    end
  end
end
