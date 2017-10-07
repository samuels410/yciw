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

import React, { Component } from 'react';
import { connect } from 'react-redux';
import { arrayOf, func, shape, string } from 'prop-types';
import I18n from 'i18n!gradebook_history';
import moment from 'moment';
import Autocomplete from 'instructure-ui/lib/components/Autocomplete';
import Button from 'instructure-ui/lib/components/Button';
import Container from 'instructure-ui/lib/components/Container';
import DateInput from 'instructure-ui/lib/components/DateInput';
import FormFieldGroup from 'instructure-ui/lib/components/FormFieldGroup';
import Spinner from 'instructure-ui/lib/components/Spinner';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import SearchFormActions from 'jsx/gradebook-history/actions/SearchFormActions';
import { showFlashAlert } from 'jsx/shared/FlashAlert';

const recordShape = shape({
  fetchStatus: string.isRequired,
  items: arrayOf(shape({
    id: string.isRequired,
    name: string.isRequired
  })),
  nextPage: string.isRequired
});

class SearchFormComponent extends Component {
  static propTypes = {
    fetchHistoryStatus: string.isRequired,
    assignments: recordShape.isRequired,
    graders: recordShape.isRequired,
    students: recordShape.isRequired,
    getGradeHistory: func.isRequired,
    clearSearchOptions: func.isRequired,
    getSearchOptions: func.isRequired,
    getSearchOptionsNextPage: func.isRequired,
  };

  state = {
    selected: {
      assignment: '',
      grader: '',
      student: '',
      from: '',
      to: ''
    },
    messages: {
      assignments: I18n.t('Type a few letters to start searching'),
      graders: I18n.t('Type a few letters to start searching'),
      students: I18n.t('Type a few letters to start searching')
    }
  };

  componentDidMount () {
    this.props.getGradeHistory(this.state.selected);
  }

  componentWillReceiveProps ({
    fetchHistoryStatus,
    assignments,
    graders,
    students
  }) {
    if (this.props.fetchHistoryStatus === 'started' && fetchHistoryStatus === 'failure') {
      showFlashAlert({ message: I18n.t('Error loading grade history. Try again?') });
    }

    if (assignments.fetchStatus === 'success' && assignments.items.length === 0) {
      this.setState(prevState => ({
        messages: {
          ...prevState.messages,
          assignments: I18n.t('No assignments with that name found')
        }
      }));
    }
    if (graders.fetchStatus === 'success' && !graders.items.length) {
      this.setState(prevState => ({
        messages: {
          ...prevState.messages,
          graders: I18n.t('No graders with that name found')
        }
      }));
    }
    if (students.fetchStatus === 'success' && !students.items.length) {
      this.setState(prevState => ({
        messages: {
          ...prevState.messages,
          students: I18n.t('No students with that name found')
        }
      }));
    }
    if (assignments.nextPage) {
      this.props.getSearchOptionsNextPage('assignments', assignments.nextPage);
    }
    if (graders.nextPage) {
      this.props.getSearchOptionsNextPage('graders', graders.nextPage);
    }
    if (students.nextPage) {
      this.props.getSearchOptionsNextPage('students', students.nextPage);
    }
  }

  setSelectedFrom = (from) => {
    const startOfFrom = from ? moment(from).startOf('day').format() : '';
    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        from: startOfFrom
      }
    }));
  }

  setSelectedTo = (to) => {
    const endOfTo = to ? moment(to).endOf('day').format() : '';
    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        to: endOfTo
      }
    }));
  }

  setSelectedAssignment = (event, selected) => {
    this.props.clearSearchOptions('assignments');
    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        assignment: selected ? selected.id : ''
      }
    }));
  }

  setSelectedGrader = (event, selected) => {
    this.props.clearSearchOptions('graders');
    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        grader: selected ? selected.id : ''
      }
    }));
  }

  setSelectedStudent = (event, selected) => {
    this.props.clearSearchOptions('students');
    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        student: selected ? selected.id : ''
      }
    }));
  }

  hasOneDate () {
    const { from, to } = this.state.selected;
    return (from !== '' && !to) || (!from && to !== '');
  }

  hasNoDates () {
    return !this.state.selected.from && !this.state.selected.to;
  }

  hasFromBeforeTo () {
    return moment(this.state.selected.to).diff(moment(this.state.selected.from), 'seconds') >= 0;
  }

  hasValidTimeFrame () {
    return this.hasFromBeforeTo() || this.hasOneDate() || this.hasNoDates();
  }

  promptUserEntry = () => {
    const emptyMessage = I18n.t('Type a few letters to start searching');
    this.setState({
      messages: {
        assignments: emptyMessage,
        graders: emptyMessage,
        students: emptyMessage
      }
    });
  }

  handleSearchEntry = (event) => {
    const target = event.target.id;
    const searchTerm = event.target.value;

    if (searchTerm.length <= 2) {
      if (this.props[target].items.length > 0) {
        this.props.clearSearchOptions(target);
        this.promptUserEntry();
      }

      return;
    }

    this.props.getSearchOptions(target, searchTerm);
  }

  handleSubmit = () => {
    if (!this.hasValidTimeFrame()) {
      return;
    }

    this.props.getGradeHistory(this.state.selected);
  }

  filterNone = options => (
    // empty function here as the default filter function for Autocomplete
    // does a startsWith call, and won't match `nora` -> `Elenora` for example
    options
  )

  renderAsOptions = data => (
    data.map(item => (
      <option key={item.id} value={item.id}>{item.name}</option>
    ))
  )

  render () {
    return (
      <Container as="div" margin="0 0 xx-large x-small">
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Search Form')}</ScreenReaderContent>}
          as="div"
          layout="columns"
          colSpacing="large"
          vAlign="bottom"
          startAt="large"
        >
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Users')}</ScreenReaderContent>}
            as="div"
            layout="columns"
            startAt="medium"
          >
            <Autocomplete
              id="students"
              allowEmpty
              emptyOption={this.state.messages.students}
              filter={this.filterNone}
              label={I18n.t('Student')}
              loading={this.props.students.fetchStatus === 'started'}
              loadingOption={<Spinner size="small" title={I18n.t('Loading Students')} />}
              onBlur={this.promptUserEntry}
              onChange={this.setSelectedStudent}
              onInputChange={this.handleSearchEntry}
            >
              {this.renderAsOptions(this.props.students.items)}
            </Autocomplete>
            <Autocomplete
              id="graders"
              allowEmpty
              emptyOption={this.state.messages.graders}
              filter={this.filterNone}
              label={I18n.t('Grader')}
              loading={this.props.graders.fetchStatus === 'started'}
              loadingOption={<Spinner size="small" title={I18n.t('Loading Graders')} />}
              onBlur={this.promptUserEntry}
              onChange={this.setSelectedGrader}
              onInputChange={this.handleSearchEntry}
            >
              {this.renderAsOptions(this.props.graders.items)}
            </Autocomplete>
            <Autocomplete
              id="assignments"
              allowEmpty
              emptyOption={this.state.messages.assignments}
              filter={this.filterNone}
              label={I18n.t('Assignment')}
              loading={this.props.assignments.fetchStatus === 'started'}
              loadingOption={<Spinner size="small" title={I18n.t('Loading Assignments')} />}
              onBlur={this.promptUserEntry}
              onChange={this.setSelectedAssignment}
              onInputChange={this.handleSearchEntry}
            >
              {this.renderAsOptions(this.props.assignments.items)}
            </Autocomplete>
          </FormFieldGroup>
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Dates')}</ScreenReaderContent>}
            layout="columns"
            startAt="small"
          >
            <DateInput
              label={I18n.t('Start Date')}
              previousLabel={I18n.t('Previous Month')}
              nextLabel={I18n.t('Next Month')}
              onDateChange={this.setSelectedFrom}
            />
            <DateInput
              label={I18n.t('End Date')}
              previousLabel={I18n.t('Previous Month')}
              nextLabel={I18n.t('Next Month')}
              onDateChange={this.setSelectedTo}
            />
          </FormFieldGroup>
          <Button
            onClick={this.handleSubmit}
            type="submit"
            variant="primary"
          >
            {I18n.t('Filter')}
          </Button>
        </FormFieldGroup>
      </Container>
    );
  }
}

const mapStateToProps = state => (
  {
    fetchHistoryStatus: state.history.fetchHistoryStatus || '',
    assignments: {
      fetchStatus: state.searchForm.records.assignments.fetchStatus || '',
      items: state.searchForm.records.assignments.items || [],
      nextPage: state.searchForm.records.assignments.nextPage || ''
    },
    graders: {
      fetchStatus: state.searchForm.records.graders.fetchStatus || '',
      items: state.searchForm.records.graders.items || [],
      nextPage: state.searchForm.records.graders.nextPage || ''
    },
    students: {
      fetchStatus: state.searchForm.records.students.fetchStatus || '',
      items: state.searchForm.records.students.items || [],
      nextPage: state.searchForm.records.students.nextPage || ''
    }
  }
);

const mapDispatchToProps = dispatch => (
  {
    getGradeHistory: (input) => {
      dispatch(SearchFormActions.getGradeHistory(input));
    },
    getSearchOptions: (recordType, searchTerm) => {
      dispatch(SearchFormActions.getSearchOptions(recordType, searchTerm));
    },
    getSearchOptionsNextPage: (recordType, url) => {
      dispatch(SearchFormActions.getSearchOptionsNextPage(recordType, url));
    },
    clearSearchOptions: (recordType) => {
      dispatch(SearchFormActions.clearSearchOptions(recordType));
    }
  }
);

export default connect(mapStateToProps, mapDispatchToProps)(SearchFormComponent);

export { SearchFormComponent };
