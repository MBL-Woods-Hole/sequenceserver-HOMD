import React, { Component } from 'react';
import _ from 'underscore';

export class Databases extends Component {
    constructor(props) {
        super(props);
        this.state = { type: '' };
        this.preSelectedDbs = this.props.preSelectedDbs;
        this.databases = this.databases.bind(this);
        this.nselected = this.nselected.bind(this);
        this.categories = this.categories.bind(this);
        this.handleClick = this.handleClick.bind(this);
        this.handleToggle = this.handleToggle.bind(this);
        this.renderDatabases = this.renderDatabases.bind(this);
        this.renderDatabase = this.renderDatabase.bind(this);
    }
    componentDidUpdate() {
        // code to preselect a single db by name
        //let db = this.databases().find(db => db.title === 'HOMD_16S_rRNA_RefSeq_V15.23.p9.fasta');
        let db = this.databases().find(db => db.title === 'HOMD_16S_rRNA_RefSeq_V16.0_full.fasta');
        if (this.databases() && db){
            $('input[value="'+db.id+'"]').prop('checked', true);
            this.handleClick(db);
        }
        // code to preselect db IF there is only one
        if (this.databases() && this.databases().length === 1) {
            $('.databases').find('input').prop('checked', true);
            this.handleClick(this.databases()[0]);
        }

        if (this.preSelectedDbs) {
            var selectors = this.preSelectedDbs.map((db) => `input[value=${db.id}]`);
            $(selectors.join(',')).prop('checked', true);
            this.handleClick(this.preSelectedDbs[0]);
            this.preSelectedDbs = null;
        }
        this.props.onDatabaseTypeChanged(this.state.type);
    }
    databases(category) {
        var databases = this.props.databases;
        if (category) {
            databases = _.select(databases, (database) => database.type === category);
        }

        return _.sortBy(databases, 'title');
    }

    nselected() {
        return $('input[name="databases[]"]:checked').length;
    }

    categories() {
        return _.uniq(_.map(this.props.databases, _.iteratee('type'))).sort();
    }

    handleClick(database) {
        var type = this.nselected() ? database.type : '';
        if (type != this.state.type) this.setState({ type: type });
    }

    handleToggle(toggleState, type) {
        switch (toggleState) {
        case '[Select all]':
            $(`.${type} .database input:not(:checked)`).click();
            break;
        case '[Deselect all]':
            $(`.${type} .database input:checked`).click();
            break;
        }
        this.forceUpdate();
    }
    renderDatabases(category) {
    // Panel name and column width.
        var panelTitle = category[0].toUpperCase() + category.substring(1).toLowerCase() + ' Databases';
        var columnClass = this.categories().length === 1 ? 'col-md-12' : 'col-md-6';

        // Toggle button.
        var toggleState = '[Select all]';
        var toggleClass = 'btn-link';
        var toggleShown = this.databases(category).length > 1;
        var toggleDisabled = this.state.type && this.state.type !== category;
        if (toggleShown && toggleDisabled) toggleClass += ' disabled';
        if (!toggleShown) toggleClass += ' hidden';
        if (this.nselected() === this.databases(category).length) {
            toggleState = '[Deselect all]';
        }

        // JSX.
        return (
            <div className={columnClass} key={'DB_' + category}>
                <div className="panel panel-default">
                    <div className="panel-heading">
                        <h4 style={{ display: 'inline' }}>{' '+panelTitle}</h4>
                    </div>
                    
                    <ul className={'list-group databases ' + category}>
                        {_.map( this.databases(category),
                              _.bind(function (database, index) {
                              
                                   return (
                                    <li className="list-group-item" key={'DB_' + category + index} >
                                        {this.renderDatabase(database)}
                                    </li>
                                   );
                        
                            }, this)
                        )}
                    </ul>
                    
                    
                </div>
            </div>
        );
    }

    renderDatabase(database) {
        //var disabled = this.state.type && this.state.type !== database.type;
        var disabled = false
        
        return (
            <label className={'database'}>
                <input
                    //type="checkbox"
                    type="radio"
                    name="databases[]"
                    value={database.id}
                    data-type={database.type}
                    disabled={disabled}
                    onChange={_.bind(function () {
                        this.handleClick(database);
                    }, this)}
                />
                  <span className='brown'>{' ' + (database.title || database.name)}</span>
            </label>
        );
    }


    render() {
        return (
            <div className="form-group databases-container">
                {_.map(this.categories(), this.renderDatabases)}
            </div>
        );
    }
}