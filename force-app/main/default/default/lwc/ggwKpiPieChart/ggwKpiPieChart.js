import { LightningElement, api, track } from "lwc";
import chartjs from '@salesforce/resourceUrl/ChartJs';
import {loadScript} from 'lightning/platformResourceLoader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

const DATA_COUNT = 5;
const NUMBER_CFG = {count: DATA_COUNT, min: 0, max: 100};

const data = {
  labels: ['New', 'Progress', 'Won', 'Rejected'],
  datasets: [
    {
      label: 'Dataset 1',
      data: [2,14,30,45],
      backgroundColor: [
        'rgba(255, 159, 64, 0.2)',
        'rgba(75, 192, 192, 0.2)',
        'rgba(25, 59, 64, 0.2)',
        'rgba(255, 15, 164, 0.2)',
      ],
  
    }
  ]
};

export default class GgwKpiPieChart extends LightningElement {
    @api loaderVariant = 'base';
    @track isChartJsInitialized;
    chart;
    error;
    title = 'Your KPI Metrics';
  

    @api chartConfig = {
        type: 'pie',
        data: data,
        options: {
          responsive: true,
          plugins: {
            legend: {
              position: 'top',
            },
            title: {
              display: true,
              text: 'Chart.js Pie Chart'
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
          
          const ctx = this.template.querySelector('canvas.pieChart').getContext('2d');
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