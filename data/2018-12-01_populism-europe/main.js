const colours = {
  red: '#db444b',
  blue: '#006ba2',
  purple: '#9a607f',
  tickMark: '#3f5661',
  neutral: '#758d99',
};

const sel = d3.select('#chart');

const width = window.innerWidth - 20;
const height = Math.min(window.innerHeight - 80, 800);

const linkThresholds = [0.05, 0.1, 0.2];
const commaFormat = d3.format(',');

const tooltip = document.getElementById('tooltip');
function constructTooltip(d, x, y, w, h) {
  tooltip.innerHTML = `
    <div>${d.country}: ${d.party_abbrev}</div>
    <div>${commaFormat(d.last_election_party_votes)}</div>
  `;
  tooltip.style.top = `${y + h}px`;
  tooltip.style.left = `${x + w}px`;
}
function clearTooltip() {
  tooltip.innerHTML = '';
  tooltip.style.top = `-100px`;
  tooltip.style.left = `-100px`;
}

const xScale = d3
  .scaleLinear()
  .domain([0, 10])
  .range([0, width]);
const yScale = d3
  .scaleLinear()
  .domain([0, 10])
  .range([height, 0]);
const voteCountScale = d3
  .scaleSqrt()
  .domain([0, 1e7])
  .range([0, 20]);
const linkColourScale = d3
  .scaleOrdinal()
  .domain(d3.range(linkThresholds.length))
  .range([colours.blue, colours.purple, colours.yellow]);

const measures = [
  'EU_integration_2017',
  'immigrate_policy_2017',
  'galtan_2017',
  'lrecon_2017',
];

function calculateMagnitude(source, target) {
  // now Euclidean distance
  return Math.sqrt(
    measures.reduce((memo, k) => {
      const s = source[k] / 10;
      const t = target[k] / 10;
      const spread = Math.abs(s - t);
      return memo + spread ** 2;
    }, 0) / measures.length, // normalize this to a maximum of 1
  );
}

async function drawChart(promise, sel) {
  sel.attr('width', width);
  sel.attr('height', height);

  const data = (await promise)
    .filter(d => d.latest_election_share > 0 && d.last_election_party_votes > 0)
    .map(d =>
      Object.assign({}, d, {
        x: xScale(d.galtan_2017), // make it left-right ish
        y: yScale(d.lrecon_2017), // make it left-right ish
        r: voteCountScale(d.last_election_party_votes),
      }),
    );

  // construct a scale for the sizing
  const sizeScaleTicks = [1e6, 5e6, 10e6, 20e6];
  const sizeScaleJoin = sel.selectAll('.size-scale-point').data(sizeScaleTicks);
  const sizeScaleJoinEnter = sizeScaleJoin
    .enter()
    .append('g')
    .classed('size-scale-point', true);
  sizeScaleJoinEnter
    .merge(sizeScaleJoin)
    .attr('transform', d => `translate(${40},${80})`);
  sizeScaleJoin.exit().remove();
  sizeScaleJoinEnter
    .append('circle')
    .merge(sizeScaleJoin.select('circle'))
    .attr('r', d => voteCountScale(d))
    .attr('cy', d => -voteCountScale(d))
    .attr('fill', 'none')
    .attr('stroke', colours.tickMark);
  sizeScaleJoinEnter
    .append('text')
    .merge(sizeScaleJoin.select('text'))
    .attr('text-anchor', 'middle')
    .attr('y', d => -2 * voteCountScale(d) + 10)
    .attr('font-size', 12)
    .text(d => d / 1e6);

  // calculate all the links for a network diagram
  const links = [];
  for (let i = 0, l = data.length; i < l; ++i) {
    for (let j = i + 1; j < l; ++j) {
      const source = data[i];
      const target = data[j];
      const magnitude = calculateMagnitude(source, target);
      const category = linkThresholds.reduce((memo, v, i) => {
        if ((memo === null) & (magnitude < v)) {
          return i;
        }
        return memo;
      }, null);
      links.push({
        source,
        target,
        magnitude,
        category,
      });
    }
  }

  // plot nodes
  const svgPos = sel.node().getBoundingClientRect();
  const nodeJoin = sel
    .select('#nodes')
    .selectAll('.party')
    .data(data);
  nodeJoin.exit().remove();
  nodeJoin
    .enter()
    .append('svg:circle')
    .classed('party', true)
    .merge(nodeJoin)
    .on('mouseenter', d =>
      constructTooltip(d, d.x, d.y, svgPos.left, svgPos.top),
    )
    .on('mouseleave', clearTooltip)
    .on('click', d => console.log(d))
    .attr('id', d => `${d.country}_${d.party_abbrev}`)
    .attr('r', d => d.r)
    .attr('cx', d => d.x)
    .attr('cy', d => d.y)
    .attr('fill', d =>
      d.antielite_salience_2017 >= 7.5 ? colours.red : colours.neutral,
    );

  // plot links
  const linkJoin = sel
    .select('#links')
    .selectAll('.link')
    .data(links.filter(link => link.category === 1 || link.category === 0));
  linkJoin.exit().remove();
  linkJoin
    .enter()
    .append('svg:line')
    .classed('link', true)
    .merge(linkJoin)
    .attr('stroke', link => linkColourScale(link.category))
    .attr('stroke-width', 0.75)
    .attr(
      'id',
      ({ source, target }) =>
        `${source.country}_${source.party_abbrev}-to-${target.country}_${
          target.party_abbrev
        }`,
    )
    .attr('opacity', link => 0.25 - link.magnitude)
    .attr('x1', link => link.source.x)
    .attr('x2', link => link.target.x)
    .attr('y1', link => link.source.y)
    .attr('y2', link => link.target.y);

  // cache these selections for the tick function
  const nodeSelection = sel.select('#nodes').selectAll('.party');
  const linkSelection = sel.select('#links').selectAll('.link');

  // the tick function runs every iteration of the force simulation,
  // updating the positions of all of the parties
  function tickOver() {
    nodeSelection
      .attr('cx', d => {
        if (d.x < xScale.range()[0]) {
          d.x = xScale.range()[0];
        }
        if (d.x > xScale.range()[1]) {
          d.x = xScale.range()[1];
        }
        return d.x;
      })
      .attr('cy', d => {
        if (d.y < yScale.range()[1]) {
          d.y = yScale.range()[1];
        }
        if (d.y > yScale.range()[0]) {
          d.y = yScale.range()[0];
        }
        return d.y;
      });

    linkSelection
      .attr('x1', link => link.source.x)
      .attr('x2', link => link.target.x)
      .attr('y1', link => link.source.y)
      .attr('y2', link => link.target.y);
  }

  // this defines the parameters of our "physics model"
  const simulation = d3
    .forceSimulation()
    .nodes(data)
    .stop()
    // this charge force is a basic global repulsion: all parties push one another away a bit
    .force('charge', d3.forceManyBody().strength(-8))
    // these three linking forces are progressively weaker attractors that draw parties in
    // towards their neighbours
    .force(
      'linkClose',
      d3
        .forceLink()
        .id(d => d.party_id)
        .strength(d => 150 / data.length)
        .links(links.filter(link => link.category === 0)),
    )
    .force(
      'linkMiddling',
      d3
        .forceLink()
        .id(d => d.party_id)
        .strength(d => 12 / data.length)
        .links(links.filter(link => link.category === 1)),
    )
    .force(
      'linkDistant',
      d3
        .forceLink()
        .id(d => d.party_id)
        .strength(d => 3 / data.length)
        .links(links.filter(link => link.category === 2)),
    )
    // the collision force prevents parties from overlapping
    .force('collide', d3.forceCollide(d => d.r + 1))
    // the centering force prevents parties from flying off the edge of the chart
    .force('centre', d3.forceCenter(width / 2, height / 2));
  simulation.on('tick', tickOver);

  setTimeout(() => {
    simulation.restart();
  }, 10);
}

const p = new Promise((resolve, reject) => {
  Papa.parse('output_data/party_stats_df.csv', {
    download: true,
    header: true,
    dynamicTyping: true,
    skipEmptyLines: true,
    complete: ({ data }) => {
      resolve(data);
    },
  });
});

drawChart(p, sel);
