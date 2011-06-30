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

module Mongoid::Categorizable
  def self.included(base)
    # create fields for categories and index it
    base.field :categories_array, :type => Array, :default => []
    base.index [['categories_array', Mongo::ASCENDING]]

    # add callback to save categories index
    base.after_save do |document|
      document.class.save_categories_index!
    end

    # extend model
    base.extend         ClassMethods
    base.send :include, InstanceMethods

    # enable indexing as default
    base.enable_categories_index!
  end

  module ClassMethods
    # returns an array of distinct ordered list of categories defined in all documents

    def categorized_with(category)
      self.any_in(:categories_array => [category])
    end

    def categorized_with_all(*categories)
      self.all_in(:categories_array => categories.flatten)
    end
    
    def categorized_with_any(*categories)
      self.any_in(:categories_array => categories.flatten)
    end

    def categories
      db = Mongoid::Config.master
      db.collection(categories_index_collection).find.to_a.map{ |r| r["_id"] }
    end

    # retrieve the list of categories with weight (i.e. count), this is useful for
    # creating category clouds
    def categories_with_weight
      db = Mongoid::Config.master
      db.collection(categories_index_collection).find.to_a.map{ |r| [r["_id"], r["value"]] }
    end

    def disable_categories_index!
      @do_categories_index = false
    end

    def enable_categories_index!
      @do_categories_index = true
    end

    def categories_separator(separator = nil)
      @categories_separator = separator if separator
      @categories_separator || ','
    end

    def categories_index_collection
      "#{collection_name}_categories_index"
    end

    def save_categories_index!
      return unless @do_categories_index

      db = Mongoid::Config.master
      coll = db.collection(collection_name)

      map = "function() {
        if (!this.categories_array) {
          return;
        }

        for (index in this.categories_array) {
          emit(this.categories_array[index], 1);
        }
      }"

      reduce = "function(previous, current) {
        var count = 0;

        for (index in current) {
          count += current[index]
        }

        return count;
      }"

      coll.map_reduce(map, reduce, :out => categories_index_collection)
    end
  end

  module InstanceMethods
    def categories
      (categories_array || []).join(self.class.categories_separator)
    end

    def categories=(categories)
      self.categories_array = categories.split(self.class.categories_separator).map(&:strip).reject(&:blank?)
    end
  end
end
