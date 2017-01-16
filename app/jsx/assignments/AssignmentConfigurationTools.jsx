define([
  'jquery',
  'react',
  'react-dom',
  'i18n!moderated_grading',
  'compiled/jquery.rails_flash_notifications'
], ($, React, ReactDOM, I18n) => {

  const AssignmentConfigurationTools = React.createClass({
    displayName: 'AssignmentConfigurationTools',

    propTypes: {
      courseId: React.PropTypes.number.isRequired,
      secureParams: React.PropTypes.string.isRequired,
      selectedTool: React.PropTypes.number,
      selectedToolType: React.PropTypes.string
    },

    componentWillMount() {
      this.getTools();
    },

    componentDidMount() {
      this.setToolLaunchUrl();
    },

    getInitialState() {
      return {
        toolLaunchUrl: 'none',
        toolType: '',
        tools: []
      };
    },

    getTools() {
      const self = this;
      const toolsUrl = this.getDefinitionsUrl();
      const data = {
        'placements[]': 'assignment_configuration'
      };

      $.ajax({
        type: 'GET',
        url: toolsUrl,
        data: data,
        success: $.proxy(function(data) {
          let prevToolLaunch = undefined;
          let prevToolType = undefined;
          if (this.props.selectedTool && this.props.selectedToolType) {
            for (var i = 0; i < data.length; i++) {
              if (data[i].definition_id == this.props.selectedTool &&
                  data[i].definition_type === this.props.selectedToolType) {
                prevToolLaunch = this.getLaunch(data[i]);
                break;
              }
            }
          }
          this.setState({
            tools: data,
            toolType: this.props.selectedToolType,
            toolLaunchUrl: prevToolLaunch || 'none'
          });
        }, self),
        error: function(xhr) {
          $.flashError(I18n.t('Error retrieving assignment configuration tools'));
        }
      });
    },

    getDefinitionsUrl() {
      return `/api/v1/courses/${this.props.courseId}/lti_apps/launch_definitions`;
    },

    getLaunch(tool) {
      const url = tool.placements.assignment_configuration.url
      let query = '';
      let endpoint = '';

      if(tool.definition_type === 'ContextExternalTool') {
        query = `?borderless=true&url=${encodeURIComponent(url)}&secure_params=${this.props.secureParams}`;
        endpoint = `/courses/${this.props.courseId}/external_tools/retrieve`;
      } else {
        query = `?display=borderless&secure_params=${this.props.secureParams}`;
        endpoint = `/courses/${this.props.courseId}/lti/basic_lti_launch_request/${tool.definition_id}`;
      }

      return endpoint + query;
    },

    setToolLaunchUrl() {
      const selector = this.refs.assignmentConfigurationTool;
      const selectedOption = selector.options[selector.selectedIndex];
      const selectedType = selectedOption.getAttribute('data-type');

      this.setState({
        toolLaunchUrl: selectedOption.getAttribute('data-launch'),
        toolType: selectedType
      });
    },

    renderOptions() {
      return (
        <select id="assignment_configuration_tool"
                name="assignmentConfigurationTool"
                onChange={this.setToolLaunchUrl}
                ref="assignmentConfigurationTool">
          <option data-launch="none">None</option>
          {
            this.state.tools.map((tool) => {
              return (
                <option
                  value={tool.definition_id}
                  data-launch={this.getLaunch(tool)}
                  data-type={tool.definition_type}
                  selected={tool.definition_id == this.props.selectedTool}
                  >
                  {tool.name}
                </option>
              );
            })
          }
        </select>
      );
    },

    renderToolType() {
      return(
        <input type="hidden" id ="configuration-tool-type" name="configuration_tool_type" value={this.state.toolType} />
      );
    },

    renderConfigTool() {
      if (this.state.toolLaunchUrl !== 'none') {
        return(
          <iframe src={this.state.toolLaunchUrl} className="tool_launch"></iframe>
        );
      }
    },

    render() {
      return (
        <div>
          <div className="form-column-left">
            <label htmlFor="assignment_configuration_tool">
              Plagiarism Review
            </label>
          </div>

          <div className="form-column-right">
            <div className="border border-trbl border-round">
              {this.renderOptions()}
              {this.renderToolType()}
              {this.renderConfigTool()}
            </div>
          </div>
        </div>
      )
    }
  });

  const attach = function(element, courseId, secureParams, selectedTool, selectedToolType) {
    const configTools = (
      <AssignmentConfigurationTools
        courseId ={courseId}
        secureParams={secureParams}
        selectedTool={selectedTool}
        selectedToolType={selectedToolType}/>
    );
    return ReactDOM.render(configTools, element);
  };

  const ConfigurationTools = {
    configTools: AssignmentConfigurationTools,
    attach: attach
  };

  return ConfigurationTools;
});
