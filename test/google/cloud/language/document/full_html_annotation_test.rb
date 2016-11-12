# Copyright 2016 Google Inc. All rights reserved.
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

require "helper"

describe Google::Cloud::Language::Document, :full_html_annotation, :mock_language do
  let(:doc) { language.document html_content, format: :html }

  it "runs full annotation" do
    grpc_doc = Google::Cloud::Language::V1::Document.new(
      content: html_content, type: :HTML)
    features = Google::Cloud::Language::V1::AnnotateTextRequest::Features.new(
      extract_syntax: true, extract_entities: true, extract_document_sentiment: true)
    grpc_resp = Google::Cloud::Language::V1::AnnotateTextResponse.decode_json html_json

    mock = Minitest::Mock.new
    mock.expect :annotate_text, grpc_resp, [grpc_doc, features, :UTF8, options: default_options]

    doc.service.mocked_service = mock
    annotation = doc.annotate
    mock.verify

    assert_html_annotation annotation
  end

  it "runs full annotation with en language options" do
    grpc_doc = Google::Cloud::Language::V1::Document.new(
      content: html_content, type: :HTML, language: "en")
    features = Google::Cloud::Language::V1::AnnotateTextRequest::Features.new(
      extract_syntax: true, extract_entities: true, extract_document_sentiment: true)
    grpc_resp = Google::Cloud::Language::V1::AnnotateTextResponse.decode_json html_json

    mock = Minitest::Mock.new
    mock.expect :annotate_text, grpc_resp, [grpc_doc, features, :UTF8, options: default_options]

    doc.service.mocked_service = mock
    doc.language = "en"
    annotation = doc.annotate
    mock.verify

    assert_html_annotation annotation
  end

  def assert_html_annotation annotation
    annotation.language.must_equal "en"

    annotation.sentiment.must_be_kind_of Google::Cloud::Language::Annotation::Sentiment
    annotation.sentiment.language.must_equal "en"
    annotation.sentiment.score.must_be_close_to 1.0
    annotation.sentiment.magnitude.must_be_close_to 1.899999976158142

    annotation.entities.must_be_kind_of ::Array
    annotation.entities.class.must_equal Google::Cloud::Language::Annotation::Entities
    annotation.entities.each do |entity|
      entity.must_be_kind_of Google::Cloud::Language::Annotation::Entity
    end
    annotation.entities.count.must_equal 2
    annotation.entities.language.must_equal "en"
    annotation.entities.unknown.map(&:name).must_equal []
    annotation.entities.people.map(&:name).must_equal ["chris"]
    annotation.entities.locations.map(&:name).must_equal ["utah"]
    annotation.entities.places.map(&:name).must_equal ["utah"]
    annotation.entities.organizations.map(&:name).must_equal []
    annotation.entities.events.map(&:name).must_equal []
    annotation.entities.artwork.map(&:name).must_equal []
    annotation.entities.goods.map(&:name).must_equal []
    annotation.entities.other.map(&:name).must_equal []

    annotation.sentences.each do |sentence|
      sentence.must_be_kind_of Google::Cloud::Language::Annotation::Sentence
      sentence.text_span.must_be_kind_of Google::Cloud::Language::Annotation::TextSpan
      sentence.sentiment.must_be_kind_of Google::Cloud::Language::Annotation::Sentence::Sentiment
    end
    annotation.sentences.map(&:text).must_equal html_sentences
    annotation.sentences.first.text.must_equal "Hello from Chris and Mike!"
    annotation.sentences.first.offset.must_equal -1
    annotation.sentences.first.must_be :sentiment?
    annotation.sentences.first.score.must_equal 1.0
    annotation.sentences.first.magnitude.must_equal 1.899999976158142

    annotation.tokens.each do |token|
      token.must_be_kind_of Google::Cloud::Language::Annotation::Token
    end
    annotation.tokens.count.must_equal 24
    token = annotation.tokens.first
    token.text.must_equal "Hello"
    token.part_of_speech.tag.must_equal :X
    token.head_token_index.must_equal 0
    token.label.must_equal :ROOT
    token.lemma.must_equal "Hello"
  end
end
