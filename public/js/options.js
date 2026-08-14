import React, { Component } from 'react';
// Component for the advanced params input field.
export class Options extends Component {
    constructor(props) {
        super(props);
        this.state = { preOpts: {}, value: '' };
        this.updateBox = this.updateBox.bind(this);
        this.optionsJSX = this.optionsJSX.bind(this);
    }

    updateBox(value) {
        this.setState({ value: value });
    }


    optionsJSX() {
        return <span className="input-group-btn dropdown">
            <button className="btn bnt-sm btn-default dropdown-toggle"
                data-toggle="dropdown">
                <i className="fa fa-caret-down"></i>
            </button>
            <ul id='advanced-params-dropdown'
                className="dropdown-menu dropdown-menu-right">
                {
                    Object.entries(this.state.preOpts).map(
                        ([key, value], index) => {
                            value = value.join(' ');
                            if (value.trim() === this.state.value.trim())
                                var className = 'yellow-background';
                            return <li key={index} className={className}
                                onClick={() => this.updateBox(value)}>
                                <strong>{key}:</strong>&nbsp;{value}
                            </li>;
                        }
                    )
                }
            </ul>
        </span>;
    }

    render() {
        var classNames = 'form-control';
        if (this.state.value.trim()) {
            classNames += ' yellow-background';
        }else{
            classNames += ' ltgray-background';
        }
        var customParams = [
            "-evalue 1.0e-25 -max_target_seqs 20",
            "-evalue 1.0e-25 -max_target_seqs 50",
            "-evalue 1.0e-25 -max_target_seqs 100",
            "-evalue 1.0e-25 -max_target_seqs 500",
            "-evalue 1.0e-25 -max_target_seqs 1000",
            "-evalue 1.0e-25 -max_target_seqs 2000",
            "-evalue 1.0e-25 -max_target_seqs 4000",
            "-evalue 1.0e-25 -max_target_seqs 8000"
        ]
        return (
            <div className="col-md-7">
                <div className="form-group">
                    <div className="col-md-12">
                        <div className="input-group">
                            <label className="control-label" htmlFor="advanced">
                                Advanced parameters:
                                <sup style={{ marginLeft: '2px' }}>
                                    <a href=''
                                        data-toggle="modal" data-target="#help">
                                        <i className="fa fa-question-circle"></i>
                                    </a>
                                </sup>
                            </label>
                            <input type="text" className={classNames}
                                onChange={e => this.updateBox(e.target.value)}
                                id="advanced" name="advanced" value={this.state.value}
                                placeholder="eg: -evalue 1.0e-5 -max_target_seqs 100"
                                title="View, and enter advanced parameters."
                            />

                <div className="mt-5 m-auto w-50">
                  PreSelected Advanced Params:&nbsp;&nbsp;
                 <select className='customAP' value={this.state.value} onChange={e => this.updateBox(e.target.value)}>
                    {customParams.map((param) => (
                      <option 
                         value={param}
                         key={param}
                         >
                         {param}
                      </option>
                    ))}
                  </select>
                </div>
                
                            {Object.keys(this.state.preOpts).length > 1 && this.optionsJSX()}
                        </div>
                    </div>
                </div>
            </div>
        );
    }

}
