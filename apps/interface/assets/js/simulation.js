import Chart from 'chart.js';

var height = document.getElementById("heightChart");
var difficulty = document.getElementById("difficultyChart")
var circulation = document.getElementById("circulationChart")
// var tx = document.getElementById("txChart")
// var mining = document.getElementById("miningChart")

var data = [];
// var data = [
//   {
//     x: 0,
//     y: 0 
//   },
// ];

// var testData = [
//   {
//     x: 0,
//     y: 0 
//   },
//   {
//     x: 1,
//     y: 1
//   },
//   {
//     x: 2,
//     y: 2
//   },
//   {
//     x: 3,
//     y: 3
//   }
// ];

// var heightChart = newChart(height, data, 'Height of Blockchain', 'linear');
var heightChart = new Chart(height, {
    type: 'line',
    data: {
        datasets: [{
            data: [],
            label: 'Left dataset',
            borderColor: "#3e95cd",
            fill: false,

            // This binds the dataset to the left y axis
            yAxisID: 'left-y-axis'
        }],
    },
    options: {
        title: {
            display: true,
            text: 'Blockchain Height'
        },
        scales: {
            yAxes: [{
                id: 'left-y-axis',
                type: 'linear',
                position: 'left',
                ticks: {
                    beginAtZero: true
                }
            }],
            xAxes: [{
                ticks: {
                    display: false
                }
            }]
        }
    }
});

// var diffChart = newChart(difficulty, data, 'Difficulty', 'linear');
var diffChart = new Chart(difficulty, {
    type: 'line',
    data: {
        datasets: [{
            data: [],
            steppedLine: true,
            borderColor: "#3e95cd",
            fill: false,
            yAxisID: 'left-y-axis'
        }]
    },
    options: {
        title: {
            display: true,
            text: 'Difficulty'
        },
        scales: {
            yAxes: [{
                id: 'left-y-axis',
                type: 'logarithmic',
                position: 'left',
                ticks: {
                    beginAtZero: true
                }
            }]   
        }
    }
});

var circChart = new Chart(circulation, {
    type: 'line',
    data: {
        datasets: [{
            data: [],
            borderColor: "#3e95cd",
            fill: false,
            yAxisID: 'left-y-axis'   
        }]
    },
    options: {
        title: {
            display: true,
            text: 'Bitcoin in Circulation'
        },
        scales: {
            yAxes: [{
                id: 'left-y-axis',
                type: 'logarithmic',
                position: 'left',
                ticks: {
                    beginAtZero: true
                }
            }]   
        }   
    }
})

// var circChart = newChart(circulation, data, 'linear');
// var txChart = newChart(tx, data, 'linear');
// var miningChart = newChart(mining, data, 'linear');

var chart = {
    h: heightChart,
    diff: diffChart,
    circ: circChart, 
    // transactions: txChart, 
    // mining: miningChart
}

/*var chart = new Chart(ctx, {
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
*/
function addData(chart, label, data) {
    chart.data.labels.push(label);
    chart.data.datasets.forEach((dataset) => {
        dataset.data.push(data);
    });
    chart.update();
}

function newChart(context, data, title, distribution) {
    var chart = new Chart(context, {
        type: 'line',
        data: {
          // labels: [],
          datasets: [{
            data: data,
            borderColor: "#3e95cd",
            fill: false
          }]
        },
        options: {
            title: {
                display: true,
                text: title
            },
            scales: {
                xAxes: [{
                    type: 'linear',
                    // distribution: 'linear'
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

    return chart;
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
