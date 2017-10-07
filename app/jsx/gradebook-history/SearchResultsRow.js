/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react';
import { bool, shape, string } from 'prop-types';
import $ from 'jquery';
import 'jquery.instructure_date_and_time'
import environment from 'jsx/gradebook-history/environment';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';
import I18n from 'i18n!gradebook_history';
import IconOffLine from 'instructure-icons/lib/Line/IconOffLine';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import Tooltip from 'instructure-ui/lib/components/Tooltip';

function anonymouslyGraded (anonymous) {
  return anonymous ? (
    <div>
      <Tooltip tip={I18n.t('Anonymously graded')}>
        <IconOffLine />
      </Tooltip>
      <ScreenReaderContent>{I18n.t('Anonymously graded')}</ScreenReaderContent>
    </div>
  ) : (
    <ScreenReaderContent>{I18n.t('Not anonymously graded')}</ScreenReaderContent>
  );
}

function displayGrade (grade, possible, displayAsPoints) {
  if (displayAsPoints) {
    return `${GradeFormatHelper.formatGrade(grade, { defaultValue: '-' })}/${GradeFormatHelper.formatGrade(possible)}`;
  }

  return GradeFormatHelper.formatGrade(grade, { defaultValue: '-' });
}

function SearchResultsRow (props) {
  const item = props.item;
  return (
    <tr>
      <td>{$.datetimeString(new Date(item.date), { format: 'medium', timezone: environment.timezone() })}</td>
      <td>{anonymouslyGraded(item.anonymous)}</td>
      <td>{item.student || I18n.t('Not available')}</td>
      <td>{item.grader || I18n.t('Not available')}</td>
      <td>{item.assignment || I18n.t('Not available')}</td>
      <td>{displayGrade(item.gradeBefore, item.pointsPossibleBefore, item.displayAsPoints)}</td>
      <td>{displayGrade(item.gradeAfter, item.pointsPossibleAfter, item.displayAsPoints)}</td>
    </tr>
  );
}

SearchResultsRow.propTypes = {
  item: shape({
    anonymous: bool.isRequired,
    assignment: string.isRequired,
    date: string.isRequired,
    displayAsPoints: bool.isRequired,
    grader: string.isRequired,
    gradeAfter: string.isRequired,
    gradeBefore: string.isRequired,
    pointsPossibleAfter: string.isRequired,
    pointsPossibleBefore: string.isRequired,
    student: string.isRequired
  }).isRequired
};

export default SearchResultsRow;
