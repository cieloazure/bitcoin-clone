import Chart from 'chart.js';

var ctx = document.getElementById("heightChart");
var data = [
  {
    x: Date.UTC(),
    y: 5 
  },
];
var chart = new Chart(ctx, {
    type: 'line',
    data: {
      datasets: [{
        label: "height",
        data: data,
        borderColor: "#3e95cd",
        fill: false
      }]
    },
    options: {
        title: {
          display: true,
          text: 'Height of Blockchain'
        },
        scales: {
            xAxes: [{
                type: 'time',
                distribution: 'linear'
            }],
            yAxes: [{
                ticks: {
                    beginAtZero:true
                }
            }]
        },
      ticks: {
        source: 'data'
      }
    }
});

function addData(chart, label, data) {
    chart.data.labels.push(label);
    chart.data.datasets.forEach((dataset) => {
        dataset.data.push(data);
    });
    chart.update();
}


export default chart;
//var ctx = document.getElementById("myChart");
//var myChart = new Chart(ctx, {
    //type: 'bar',
    //data: {
        //labels: ["Red", "Blue", "Yellow", "Green", "Purple", "Orange"],
        //datasets: [{
            //label: '# of Votes',
            //data: [12, 19, 3, 5, 2, 3],
            //backgroundColor: [
                //'rgba(255, 99, 132, 0.2)',
                //'rgba(54, 162, 235, 0.2)',
                //'rgba(255, 206, 86, 0.2)',
                //'rgba(75, 192, 192, 0.2)',
                //'rgba(153, 102, 255, 0.2)',
                //'rgba(255, 159, 64, 0.2)'
            //],
            //borderColor: [
                //'rgba(255,99,132,1)',
                //'rgba(54, 162, 235, 1)',
                //'rgba(255, 206, 86, 1)',
                //'rgba(75, 192, 192, 1)',
                //'rgba(153, 102, 255, 1)',
                //'rgba(255, 159, 64, 1)'
            //],
            //borderWidth: 1
        //}]
    //},
    //options: {
        //scales: {
            //yAxes: [{
                //ticks: {
                    //beginAtZero:true
                //}
            //}]
        //}
    //}
//});
