import React, { Component, useState } from 'react';

//import Select from "react-select";

import _ from 'underscore';

import downloadFASTA from './download_fasta';
import AlignmentExporter from './alignment_exporter'; // to download textual alignment

/**
 * Renders links for downloading hit information in different formats.
 * Renders links for navigating to each query.
 */
export default class extends Component {

    constructor(props) {
        super(props);
        this.downloadFastaOfAll = this.downloadFastaOfAll.bind(this);
        this.downloadFastaOfSelected = this.downloadFastaOfSelected.bind(this);
        this.downloadAlignmentOfAll = this.downloadAlignmentOfAll.bind(this);
        this.downloadAlignmentOfSelected = this.downloadAlignmentOfSelected.bind(this);
        this.topPanelJSX = this.topPanelJSX.bind(this);
        this.summaryString = this.summaryString.bind(this);
        this.indexJSX = this.indexJSX.bind(this);
        this.downloadsPanelJSX = this.downloadsPanelJSX.bind(this);
        this.copyURL = this.copyURL.bind(this);
        this.mailtoLink = this.mailtoLink.bind(this);
        this.sharingPanelJSX = this.sharingPanelJSX.bind(this);


        this.state = {
         query: "banana",
        };

        this.handleChange = this.handleChange.bind(this);

    }
    /**
         * Clear sessionStorage - useful to initiate a new search in the same tab.
         * Passing sessionStorage.clear directly as onclick callback didn't work
         * (on macOS Chrome).
        */
    clearSession() {
        sessionStorage.clear();
    }

    /**
     * Event-handler for downloading fasta of all hits.
     */
    downloadFastaOfAll() {
        var sequence_ids = [];
        this.props.data.queries.forEach(
            (query) => query.hits.forEach(
                (hit) => sequence_ids.push(hit.id)));
        var database_ids = this.props.data.querydb.map((querydb) => querydb.id);
        downloadFASTA(sequence_ids, database_ids);
        return false;
    }

    /**
     * Handles downloading fasta of selected hits.
     */
    downloadFastaOfSelected() {
        var sequence_ids = $('.hit-links :checkbox:checked').map(function () {
            return this.value;
        }).get();
        var database_ids = _.map(this.props.data.querydb, _.iteratee('id'));
        downloadFASTA(sequence_ids, database_ids);
        return false;
    }

    downloadAlignmentOfAll() {
        // Get number of hits and array of all hsps.
        var num_hits = 0;
        var hsps_arr = [];
        this.props.data.queries.forEach(
            (query) => query.hits.forEach(
                (hit) => {
                    num_hits++;
                    hit.hsps.forEach((hsp) => {
                        hsp.query_id = query.id;
                        hsp.hit_id = hit.id;
                        hsps_arr.push(hsp);
                    });
                }
            )
        );

        var aln_exporter = new AlignmentExporter();
        var file_name = `alignment-${num_hits}_hits`;
        aln_exporter.export_alignments(hsps_arr, file_name);
        return false;
    }

    downloadAlignmentOfSelected() {
        var sequence_ids = $('.hit-links :checkbox:checked').map(function () {
            return this.value;
        }).get();
        var hsps_arr = [];
        var aln_exporter = new AlignmentExporter();
        //console.log('check ' + sequence_ids.toString());
        _.each(this.props.data.queries, _.bind(function (query) {
            _.each(query.hits, function (hit) {
                if (_.indexOf(sequence_ids, hit.id) != -1) {
                    _.each(hit.hsps, function (hsp) {
                        hsp.hit_id = hit.id;
                        hsp.query_id = query.id;
                        hsps_arr.push(hsp);
                    });
                }
            });
        }, this));
        aln_exporter.export_alignments(hsps_arr, 'alignment-' + sequence_ids.length + '_hits');
        return false;
    }

    /**
     * Fixes tooltips in the sidebar, allows tooltip display on click
     */
    componentDidMount() {
        $(function () {
            $('.sidebar [data-toggle="tooltip"]').tooltip({ placement: 'right' });
            $('#copyURL').tooltip({ title: 'Copied!', trigger: 'click', placement: 'right', delay: 0 });
        });
    }

    /**
     * Handles copying the URL into the user's clipboard. Modified from: https://stackoverflow.com/a/49618964/18117380
     * Hides the 'Copied!' tooltip after 3 seconds
     */

    copyURL() {
        var element = document.createElement('input');
        var url = window.location.href;
        document.body.appendChild(element);
        element.value = url;
        element.select();
        document.execCommand('copy');
        document.getSelection().removeAllRanges();
        document.body.removeChild(element);

        setTimeout(function () {
            $('#copyURL')._tooltip('destroy');
        }, 3000);
    }

    /**
     * Returns a mailto message with at most 15 databases used
     */
    mailtoLink() {
        // Iterates over the databases used and appends the first 15 to an array with string formatting
        var dbsArr = [];
        let i = 0;
        while (this.props.data.querydb[i] && i < 15) {
            dbsArr.push(' ' + this.props.data.querydb[i].title);
            i += 1;
        }

        // returns the mailto message
        var mailto = `mailto:?subject=HOMD ${this.props.data.program.toUpperCase()} analysis results &body=Hello,

        Here is a link to my recent ${this.props.data.program.toUpperCase()} analysis.
            ${window.location.href}
        
        This link will be valid for 30 days.
        
        This search was done against the:
            ${dbsArr[0]}

        Thank you for using HOMD SequenceServer. 
        Please cite eHOMD V3.1 (https://journals.asm.org/doi/10.1128/msystems.00187-18)
        www.homd.org

        Best regards,`;
        

        var message = encodeURI(mailto).replace(/(%20){2,}/g, '');
        return message;
    }

    topPanelJSX() {
        var path = location.pathname.split('/');
        // Get job id.
        var job_id = path.pop();
        // Deriving rootURL this way is required for subURI deployments
        // - we cannot just send to '/'.
        var rootURL = path.join('/');
        return (
            <div className="sidebar-top-panel">
                <div className="section-header-sidebar">
                    <h4>
                        {this.summaryString()}
                    </h4>
                </div>
                <div>
                    <a href={`${rootURL}/?job_id=${job_id}`}>
                        <i className="fa fa-pencil"></i> Edit search
                    </a>
                    <span className="line">|</span>
                    <a href={`${rootURL}/`}
                        onClick={this.clearSession}>
                        <i className="fa fa-file-o"></i> New search
                    </a>
                </div>
                
                {this.indexJSX()}
            </div>
        );
    }

    summaryString() {
        var program = this.props.data.program;
        var numqueries = this.props.data.queries.length;
        var numquerydb = this.props.data.querydb.length;

        return (
            program.toUpperCase() + ': ' +
            numqueries + ' ' + (numqueries > 1 ? 'queries' : 'query') + ', ' +
            numquerydb + ' ' + (numquerydb > 1 ? 'databases' : 'database')
        );
    }


    scrollToAnchor(divid){
       var aTag = $("div[id='"+ divid +"']");
       //var aTag = $("div[id='Query_3']");
       $('html,body').animate({scrollTop: aTag.offset().top - 50},'slow');
    }
    scrollToTop(){
       $("html, body").animate({ scrollTop: "0" },"slow");
    }
    handleChange(e) {
        var anchor = e.target.value.replace('#','')  // remove '#'
        if(anchor === 'top'){
           $("html, body").animate({ scrollTop: "0" },"slow");
        }else{
           this.scrollToAnchor(anchor)
        }
       
        this.setState({ query: e.target.value });
    }
    
    indexJSX() {
      
      if(this.props.data.queries.length == 1){
        return <a className='scroll'
                  href='#'
                  onClick={this.scrollToTop}>
                  <i className="fa fa-angle-double-up"></i> Scroll to Top
                 </a>
                
      }else{
          const options = _.map(this.props.data.queries, (q) => {
             return {key:q.number, value: '#Query_' + q.number, label: 'Query= ' + q.id + ' ' + q.title }
          })

          return <div className="container">
              <a className='scroll'
                  href='#'
                  onClick={this.scrollToTop}>
                  <i className="fa fa-angle-double-up"></i> Scroll to Top
                 </a>
              <div className="mt-5 m-auto w-50">Queries:&nbsp;&nbsp;
                 <select className='qselect' value={this.state.query} onChange={this.handleChange}>
                    {options.map((option) => (
                      <option 
                         value={option.value}
                         key={option.value}
                         >
                         {option.label}
                         </option>
                    ))}
                  </select>
              </div>
            </div>
      }
       
    
    }
    downloadsPanelJSX() {
        return (
            <div className="downloads">
                <div className="section-header-sidebar">
                    <h4>
                        Download FASTA, XML, TSV
                    </h4>
                </div>
                <ul className="nav">
                    {
                        !(this.props.data.imported_xml || this.props.data.non_parse_seqids) && <li>
                            <a href="#" className={`btn-link download-fasta-of-all ${!this.props.atLeastOneHit && 'disabled'}`}
                                onClick={this.downloadFastaOfAll}>
                                FASTA of all hits
                            </a>
                        </li>
                    }
                    {
                        !(this.props.data.imported_xml || this.props.data.non_parse_seqids) && <li>
                            <a href="#" className="btn-link download-fasta-of-selected disabled"
                                onClick={this.downloadFastaOfSelected}>
                                FASTA of <span className="text-bold"></span> selected hit(s)
                            </a>
                        </li>
                    }
                    <li>
                        <a href="#" className={`btn-link download-alignment-of-all ${!this.props.atLeastOneHit && 'disabled'}`}
                            onClick={this.downloadAlignmentOfAll}>
                            Alignment of all hits
                        </a>
                    </li>
                    <li>
                        <a href="#" className="btn-link download-alignment-of-selected disabled"
                            onClick={this.downloadAlignmentOfSelected}>
                            Alignment of <span className="text-bold"></span> selected hit(s)
                        </a>
                    </li>
                    {
                        !this.props.data.imported_xml && <li>
                            <a className="btn-link download" data-toggle="tooltip"
                                title="15 columns: query and subject ID; scientific
                                name, alignment length, mismatches, gaps, identity,
                                start and end coordinates, e value, bitscore, query
                                coverage per subject and per HSP."
                                href={'download/' + this.props.data.search_id + '.std_tsv'}>
                                Standard tabular report
                            </a>
                        </li>
                    }
                    {
                        !this.props.data.imported_xml && <li>
                            <a className="btn-link download" data-toggle="tooltip"
                                title="44 columns: query and subject ID, GI,
                                accessions, and length; alignment details;
                                taxonomy details of subject sequence(s) and
                                query coverage per subject and per HSP."
                                href={'download/' + this.props.data.search_id + '.full_tsv'}>
                                Full tabular report
                            </a>
                        </li>
                    }
                    {
                        !this.props.data.imported_xml && <li>
                            <a className="btn-link download" data-toggle="tooltip"
                                title="Results in XML format."
                                href={'download/' + this.props.data.search_id + '.xml'}>
                                Full XML report
                            </a>
                        </li>
                    }
                    {
                      <li>
                            <a className="btn-link download" data-toggle="tooltip"
                                title="Link to HOMD - View Tree of this BLAST Result."
                                href={'https://devel.homd.org/blastdir=' + this.props.data.search_id }
                                target='_blank'>
                                View Phylogenetic Tree
                            </a>
                      </li>
                    }
                </ul>
            </div>
        );
    }

    sharingPanelJSX() {
        return (
            <div className="sharing-panel">
                <div className="section-header-sidebar">
                    <h4>
                        Share results
                    </h4>
                </div>
                <ul className="nav">
                    {
                        <li>
                            <a id="copyURL" className="btn-link copy-URL cursor-pointer" data-toggle="tooltip"
                                onClick={this.copyURL}>
                                <i className="fa fa-copy"></i> Copy URL to clipboard
                            </a>
                        </li>
                    }
                    {
                        <li>
                            <a id="sendEmail" className="btn-link email-URL cursor-pointer" data-toggle="tooltip"
                                title="Send by email" href={this.mailtoLink()}
                                target="_blank" rel="noopener noreferrer">
                                <i className="fa fa-envelope"></i> Send by email
                            </a>
                        </li>
                    }
                </ul>
            </div>
        );
    }

    render() {
        return (
            <div className="sidebar">
                {this.topPanelJSX()}
                {this.downloadsPanelJSX()}
                {this.sharingPanelJSX()}
            </div>
        );
    }
}

