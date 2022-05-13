import {LightningElement, api, track} from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import {loadScript} from 'lightning/platformResourceLoader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';


const labels = ['Jan', 'Feb', 'Mar','April','May','June'];
const data = {
  labels: labels,
  datasets: [{
    label: 'Current',
    data: [1.5, 2.1, 3.0, 2.5, 3.0, 3.0],
    backgroundColor: [
      'rgba(255, 159, 64, 0.2)',
      'rgba(255, 159, 64, 0.2)',
      'rgba(255, 159, 64, 0.2)',
      'rgba(255, 159, 64, 0.2)',
      'rgba(255, 159, 64, 0.2)',
      'rgba(255, 159, 64, 0.2)',
    ],
    borderColor: [
      'rgb(255, 159, 64)',
      'rgb(255, 159, 64)',
      'rgb(255, 159, 64)',
      'rgb(255, 159, 64)',
      'rgb(255, 159, 64)',
      'rgb(255, 159, 64)',
    ],
    borderWidth: 1
  },
  {
    label: 'Recommended',
    data: [2.5, 3.0, 4.0, 3.0, 4.0, 4.0],
    backgroundColor: [
      'rgba(75, 192, 192, 0.2)',
      'rgba(75, 192, 192, 0.2)',
      'rgba(75, 192, 192, 0.2)',
      'rgba(75, 192, 192, 0.2)',
      'rgba(75, 192, 192, 0.2)',
      'rgba(75, 192, 192, 0.2)',
    ],
    borderColor: [
      'rgb(75, 192, 192)',
      'rgb(75, 192, 192)',
      'rgb(75, 192, 192)',
      'rgb(75, 192, 192)',
      'rgb(75, 192, 192)',
      'rgb(75, 192, 192)',
    ],
    borderWidth: 1
  }  
  ]
};


export default class GgwBarChart extends LightningElement {
  @api loaderVariant = 'base';
  @track isChartJsInitialized;
  @api swimlane = 'Operations';
  chart;
  error;
  title = 'Organization Grants';


  @api chartConfig = {
    type: 'bar',
    data: data,
    options: {
      scales: {
        y: {
          beginAtZero: true
        }
      }
    },
  };



 renderedCallback() {
  if (this.isChartJsInitialized) {
   return;
  }
  // load static resources.
  this.isChartJsInitialized = true;
  Promise.all([loadScript(this, chartjs)])
  .then(() => {
    
    const ctx = this.template.querySelector('canvas.barChart').getContext('2d');
    //this.chart = new window.Chart(ctx, JSON.parse(JSON.stringify(this.chartConfig)));
    this.chart = new window.Chart(ctx, this.chartConfig);

    this.chart.canvas.parentNode.style.height = 'auto';
    this.chart.canvas.parentNode.style.width = '100%';
  })
  .catch(error => {
     console.log('ERROR: '+error);
     this.dispatchEvent(
      new ShowToastEvent({
       title: 'Error loading ChartJS',
       message: error.message,
       variant: 'error',
      })
     );
   });

 }
}