#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require_relative '../../spec_helper'
require_relative "../graphql_spec_helper"

describe Types::AccountType do
  before(:once) do
    teacher_in_course(active_all: true)
    student_in_course(active_all: false)
    account_admin_user
    @sub_account = account_model parent_account: @course.root_account
  end

  let(:account) { @course.root_account }
  let(:account_type) { GraphQLTypeTester.new(account, current_user: @teacher) }

  it "works" do
    expect(account_type.resolve(:name)).to eq account.name
    expect(account_type.resolve(:_id)).to eq account.id.to_s
  end

  it "requires read permission" do
    expect(account_type.resolve(:name, current_user: @student)).to be_nil
  end

  it 'works for field proficiency_ratings_connection' do
    outcome_proficiency_model(account)
    expect(
      account_type.resolve('proficiencyRatingsConnection { nodes { _id } }').sort
    ).to eq OutcomeProficiencyRating.all.map { |r| r.id.to_s }.sort
  end

  it 'works for courses' do
    expect(account_type.resolve('coursesConnection { nodes { _id } }', current_user: @admin)).to eq [@course.id.to_s]
  end

  it 'requires read_course_list permission' do
    expect(account_type.resolve('coursesConnection { nodes { _id } }', current_user: @teacher)).to be_nil
  end

  it 'works for subaccounts' do
    expect(account_type.resolve('subAccountsConnection { nodes { _id } }')).to eq [@sub_account.id.to_s]
  end
end
