#'@title Create Regions of Interest (ROI) Graphic
#'
#'@decription Create ROI graphic with data extracted from the data imported
#'via [read_RF2R]. This function is used internally by [analyse_IRSAR.RF] but
#'might be of use to work with reduced data from spatially resolved measurements.
#'The plot dimensions mimic the original image dimensions
#'
#'@param object [RLum.Analysis-class] or a [list] of such objects (**required**):
#'data input. Please note that to avoid function errors, only input created
#'by the function [read_RF2R] is accepted
#'
#'@param exclude_ROI [numeric] (*with default*): option to remove particular ROIs from the
#'analysis. Those ROIs are plotted but not coloured and not taken into account
#'in distance analysis. `NULL` excludes nothing.
#'
#'@param dist_thre [numeric] (*optional*): euclidean distance threshold in pixel
#'distance. All ROI for which the euclidean distance is smaller are marked. This
#'helps to identify ROIs that might be affected by signal cross-talk. Note:
#'the distance is calculated from the centre of an ROI, e.g., the threshold
#'should include consider the ROIs or grain radius.
#'
#'@param dim.CCD [numeric] (*optional*): metric x and y for the recorded (chip)
#'surface in µm. For instance `c(8192,8192)`, if set additional x and y-axes are shown
#'
#'@param plot [logical] (*with default*): enable or disable plot output to use
#'the function only to extract the ROI data
#'
#'@param ... further parameters to manipulate the plot. On top of all arguments of
#'[graphics::plot.default] the following arguments are supported: `lwd.ROI`, `lty.ROI`,
#'`col.ROI`, `col.pixel`, `text.labels`, `text.offset`, `grid` (`TRUE/FALSE`), `legend` (`TRUE/FALSE`),
#'`legend.text`, `legend.pos`
#'
#'@return An ROI plot and an [RLum.Results-class] object with a matrix containing
#'the extracted ROI data and a object produced by [stats::dist] containing
#'the euclidean distance between the ROIS.
#'
#'@section Function version: 0.1.0
#'
#'@author Sebastian Kreutzer, Department of Geography & Earth Sciences, Aberystwyth University
#' (United Kingdom)
#'
#'@seealso [read_RF2R], [analyse_IRSAR.RF]
#'
#'@keywords datagen plot
#'
#'@examples
#'file <- system.file("extdata", "RF_file.rf", package = "Luminescence")
#'temp <- read_RF2R(file)
#'plot_ROI(temp)
#'
#'@md
#'@export
plot_ROI <- function(
  object,
  exclude_ROI = c(1),
  dist_thre = -Inf,
  dim.CCD = NULL,
  plot = TRUE,
  ...) {
  ##helper function to extract content
  .spatial_data <- function(x) {
    ##ignore all none RLum.Analysis
    if (class(x) != "RLum.Analysis" || x@originator != "read_RF2R") {
      stop("[plot_RegionsOfInterest()] At least one input element is not of type 'RLum.Analysis' and/or does
      was not produced by 'read_RF2R()`!", call. = FALSE)
    }

    ##extract some of the elements
    info <- x@info
    info$ROI <- strsplit(split = " ", info$ROI, fixed = TRUE)[[1]][2]

    c(ROI = info$ROI,
      x = info$x,
      y = info$y,
      area = info$area,
      width = info$width,
      height = info$height,
      img_width = info$image_width,
      img_height = info$image_height,
      grain_d = info$grain_d)

  }

  ## make sure the object is a list
  if(!is.list(object)) object <- list(object)

  ##extract values and convert to numeric matrix
  m <- t(vapply(object, .spatial_data, character(length = 9)))

  ##make numeric
  storage.mode(m) <- "numeric"

  ##make sure the ROI selection works
  if(is.null(exclude_ROI[1]) || exclude_ROI[1] <= 0)
    exclude_ROI <- nrow(m) + 1

  ## add mid_x and mid_y
  m <- cbind(m, mid_x = c(m[,"x"] + m[,"width"] / 2), mid_y =  c(m[,"y"] + m[,"height"] / 2))
  rownames(m) <- m[,"ROI"]

  ## distance calculation
  euc_dist <- sel_euc_dist <- stats::dist(m[-exclude_ROI,c("mid_x","mid_y")])


  ## distance threshold selector
  sel_euc_dist[sel_euc_dist < dist_thre[1]] <- NA
  sel_euc_dist <- suppressWarnings(as.numeric(rownames(na.exclude(as.matrix(sel_euc_dist)))))

  ## add information to matrix
  m <- cbind(m, dist_sel = FALSE)
  m[m[,"ROI"]%in%sel_euc_dist,"dist_sel"] <- TRUE

  ## --- Plotting ---
  if(plot) {
    plot_settings <- modifyList(x = list(
      xlim = c(0, max(m[, "img_width"])),
      ylim = c(max(m[, "img_height"]), 0),
      xlab = "width [px]",
      ylab = "height [px]",
      main = "Spatial ROI Distribution",
      frame.plot = FALSE,
      lwd.ROI = 0.75,
      lty.ROI = 2,
      col.ROI = "black",
      col.pixel = rgb(0,1,0,0.6),
      text.labels = m[,"ROI"],
      text.offset = 0.3,
      grid = FALSE,
      legend = TRUE,
      legend.text = c("ROI", "sel. pixel", "> dist_thre"),
      legend.pos = "topright"
    ), val = list(...))


    ## set plot area
    do.call(
      what = plot.default,
      args = c(x = NA, y = NA,
               plot_settings[names(plot_settings) %in% methods::formalArgs(plot.default)])
    )

    if (plot_settings$grid) grid(nx = max(m[,"img_width"]), ny = max(m[,"img_height"]))

    ## plot metric scale
    if (!is.null(dim.CCD)) {
      axis(
        side = 1,
        at = axTicks(1),
        labels = paste(floor(dim.CCD[1] / max(m[,"img_width"]) * axTicks(1)), "\u00b5m"),
        lwd = -1,
        lwd.ticks = -1,
        line = -2.2,
        cex.axis = 0.8
      )
      axis(
        side = 2,
        at = axTicks(2)[-1],
        labels = paste(floor(dim.CCD[2] / max(m[,"img_height"]) * axTicks(2)), "\u00b5m")[-1],
        lwd = -1,
        lwd.ticks = -1,
        line = -2.2,
        cex.axis = 0.8
      )
    }

    ## add circles and rectangles
    for (i in 1:nrow(m)) {
      if (!i%in%exclude_ROI) {
        ## mark selected pixels
        polygon(
          x = c(m[i, "x"], m[i, "x"], m[i, "x"] + m[i, "width"], m[i, "x"] + m[i, "width"]),
          y = c(m[i, "y"], m[i, "y"] + m[i, "height"], m[i, "y"] + m[i, "height"], m[i, "y"]),
          col = plot_settings$col.pixel
        )
      }

      ## add ROIs
      shape::plotellipse(
        rx = m[i, "width"] / 2,
        ry = m[i, "width"] / 2,
        mid = c(m[i, "x"] + m[i, "width"] / 2, m[i, "y"] + m[i, "height"] / 2),
        lcol = plot_settings$col.ROI,
        lty = plot_settings$lty.ROI,
        lwd = plot_settings$lwd.ROI)

    }

    ## add distance marker
    points(
      x = m[!m[,"ROI"]%in%sel_euc_dist & !m[,"ROI"]%in%exclude_ROI, "x"],
      y = m[!m[,"ROI"]%in%sel_euc_dist & !m[,"ROI"]%in%exclude_ROI, "y"],
      pch = 4,
      col = "red")

    ## add text
    if(length(m[-exclude_ROI,"x"]) > 0) {
      graphics::text(
         x = m[-exclude_ROI, "x"],
         y = m[-exclude_ROI, "y"],
         labels = plot_settings$text.labels[-exclude_ROI],
         cex = 0.6,
         pos = 3,
         offset = plot_settings$text.offset
       )
    }

    ##add legend
    if(plot_settings$legend) {
      legend(
        plot_settings$legend.pos,
        bty = "n",
        pch  = c(1, 15, 4),
        legend = plot_settings$legend.text,
        col = c(plot_settings$col.ROI, plot_settings$col.pixel, "red")
      )

    }

  }##end if plot

  ## return results
  return(set_RLum(
    class = "RLum.Results",
    data = list(
      ROI = m,
      euc_dist = euc_dist),
    info = list(
      call = sys.call()
    )))


}

