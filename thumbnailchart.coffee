
class CThumbnailChart
	constructor: ()->

	getMonthlyTicks: (data)->
		formatYear = d3.time.format('%y')
		formatMonth = d3.time.format('%m')
		parseDate = d3.time.format('%Y-%m-%d').parse
		xticks = []
		tradeDate = data[0].tradeDate
		currentMonth = parseInt(formatMonth(parseDate(tradeDate)))
		currentYear = parseInt(formatYear(parseDate(tradeDate)))

		for i in [1..data.length-1]
			tradeDate = parseDate(data[i].tradeDate)
			year = parseInt(formatYear(tradeDate))
			if year!=currentYear
				currentYear = year
				continue

			month = parseInt(formatMonth(tradeDate))
			if month==currentMonth then continue
			currentMonth = month
			xticks.push(i)
		return xticks


	initXaxis: (price, chartRect, orientation)->
		self = this
		ticks = self.getMonthlyTicks(price)
		scale = d3.scale.linear().range([chartRect.left, chartRect.right]).domain([0, price.length])
		axis = d3.svg.axis().scale(scale).orient(orientation)
							 .tickSize(-chartRect.height).ticks(ticks.length).tickValues(ticks)
							 .tickFormat((d)-> 
							 	dateStr = price[d].tradeDate
							 	yy = dateStr.slice(2,4)
							 	mm = dateStr.slice(5,7)
							 	return mm + '/' + yy
								)
		return {axis:axis, scale:scale}



	initYaxis: (price, chartRect, orientation, maxTicks=0)->
		min = d3.min(price, (d)->d.low)
		max = d3.max(price, (d)->d.high)
		scale = d3.scale.linear().range([chartRect.bottom, chartRect.top]).domain([min, max])
		axis = d3.svg.axis().scale(scale).orient(orientation).tickSize(-chartRect.width).ticks(maxTicks)
							 .tickFormat((d)->
							 	decimals = 0
							 	suffix = ''
							 	if max<1 then decimals=2
							 	if max>1000 
							 		d = d/1000
							 		suffix = 'K'
							 	return d.toFixed(decimals) + suffix
							 	)
		return {axis:axis, scale:scale}



	draw: (price, chartInfo, orientation)->
		@xAxis = @initXaxis(price, chartInfo.rect, orientation.xAxis)
		@yAxis = @initYaxis(price, chartInfo.rect, orientation.yAxis, chartInfo.maxYticks)

		chart = d3.select('#' + chartInfo.svgId).attr('width', chartInfo.rect.width).attr('height', chartInfo.rect.height)
		@svg = chart.append('g').attr('class', 'svg-' + chartInfo.svgId).attr('transform', "translate(0,0)")

		#draw chart boundary
		boundRect = @svg.append('g').attr('class', 'bound-rect')
		boundRect.append('path').attr('d', (d)-> "M0,0 L#{chartInfo.rect.right},0") #top
		boundRect.append('path').attr('d', (d)-> "M0,#{chartInfo.rect.bottom} L#{chartInfo.rect.right},#{chartInfo.rect.bottom}") #bottom
		boundRect.append('path').attr('d', (d)-> "M#{chartInfo.rect.right},0 L#{chartInfo.rect.right},#{chartInfo.rect.bottom}") #right
		boundRect.append('path').attr('d', (d)-> "M0,0 L0,#{chartInfo.rect.bottom}") #left

		#draw xaxis, yaxis
		@svg.append('g').attr('class', 'x axis').attr('transform', "translate(#{chartInfo.rect.left},#{chartInfo.rect.bottom})").call(@xAxis.axis)
		@svg.append('g').attr('class', 'y axis').attr('transform', "translate(#{chartInfo.rect.right},0)").call(@yAxis.axis)

		#draw price bar
		priceBar = @svg.append('g').attr('class', 'price-chart')
		xscale = @xAxis.scale
		yscale = @yAxis.scale
		priceBar.selectAll('.price-bar')
				  .data(price).enter()
				  .append('g')
				  .attr('class', 'price-bar')
				  .append('path').attr('d', (d, i)-> "M#{xscale(i)},#{yscale(d.high)} L#{xscale(i)},#{yscale(d.low)}")
				  .append('path').attr('d', (d, i)->"M#{xscale(i)},#{yscale(d.close)} L#{xscale(i)+chartInfo.barHeight},#{yscale(d.close)}")
				  .append('path').attr('d', (d, i)->"M#{xscale(i)},#{yscale(d.open)} L#{xscale(i)-chartInfo.barHeight},#{yscale(d.open)}")



	drawOverlayChart: (id, data, color, chartRect, yRange, yScale)->
		self = this
		if yScale==undefined
			yScale = @yAxis.scale
		line = d3.svg.line().x((d, i)-> self.xAxis.scale(i)).y((d)-> yScale(d))
		chart = self.svg.append('g').attr('class', id + ' overlay').attr('transform', "translate(#{chartRect.left},#{chartRect.top})")
		chart.append('path').datum(data).attr('class', id).attr('d', line).style(stroke:color)



	drawLegend: (legend)->
		for l in legend
			@svg.append('text').attr('class', l.id + ' legend')
			   .attr('x', l.x).attr('y', l.y).attr('stroke', l.color).attr('fill', l.color)
			   .text(l.id.toUpperCase())



ThumbnailChart = new CThumbnailChart
module.exports = {ThumbnailChart}
